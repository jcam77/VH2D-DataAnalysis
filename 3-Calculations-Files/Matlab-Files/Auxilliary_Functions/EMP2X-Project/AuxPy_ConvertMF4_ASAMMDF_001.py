#!/usr/bin/env python3
"""Convert MDF/MF4 channels to CSV using asammdf.

This helper is called by AuxFcn_ReadDAQ_MF4_ASAMMDF_001.m. It keeps Python
package handling outside MATLAB's data-conversion layer and writes a simple
CSV that MATLAB can read reliably.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def call_version_tolerant(func, **kwargs):
    """Call asammdf methods while tolerating older keyword sets."""
    while True:
        try:
            return func(**kwargs)
        except TypeError as exc:
            message = str(exc)
            marker = "unexpected keyword argument "
            if marker not in message:
                raise
            bad_kwarg = message.split(marker, 1)[1].strip().strip("'\"")
            if bad_kwarg not in kwargs:
                raise
            kwargs.pop(bad_kwarg)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="Input .mf4/.mdf file")
    parser.add_argument("--output-csv", required=True, help="Output CSV path")
    parser.add_argument("--output-json", required=True, help="Output metadata JSON path")
    parser.add_argument("--group-index", type=int, default=0, help="Zero-based MDF channel group index; kept for compatibility")
    parser.add_argument("--raster", type=float, default=0.0, help="Optional resampling raster in seconds")
    parser.add_argument("--channels", default="", help="Comma-separated channel names to export")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    try:
        from asammdf import MDF
    except Exception as exc:  # pragma: no cover - surfaced to MATLAB
        raise SystemExit(
            "Python package 'asammdf' is not installed in MATLAB's Python. "
            "Install with: python3 -m pip install --user asammdf"
        ) from exc

    input_path = Path(args.input).expanduser()
    output_csv = Path(args.output_csv).expanduser()
    output_json = Path(args.output_json).expanduser()

    if not input_path.is_file():
        raise FileNotFoundError(f"MF4 file not found: {input_path}")

    mdf = MDF(str(input_path))
    raster = args.raster if args.raster and args.raster > 0 else None
    channels = [item.strip() for item in args.channels.split(",") if item.strip()]

    dataframe_kwargs = {
        "raster": raster,
        "time_from_zero": True,
        "empty_channels": "skip",
        "use_display_names": False,
        "reduce_memory_usage": False,
    }

    if channels:
        dataframe_kwargs["channels"] = channels

    df = call_version_tolerant(mdf.to_dataframe, **dataframe_kwargs)

    df = df.reset_index()
    if len(df.columns) >= 1:
        df.rename(columns={df.columns[0]: "time_s"}, inplace=True)

    output_csv.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(output_csv, index=False)

    metadata = {
        "input": str(input_path),
        "group_index_zero_based": args.group_index,
        "read_mode": "all_groups_to_dataframe",
        "raster_s": raster,
        "columns": list(map(str, df.columns)),
        "n_samples": int(len(df.index)),
        "n_channels": max(0, int(len(df.columns) - 1)),
        "asammdf_version": __import__("asammdf").__version__,
    }
    output_json.write_text(json.dumps(metadata, indent=2), encoding="utf-8")

    try:
        mdf.close()
    except Exception:
        pass


if __name__ == "__main__":
    main()
