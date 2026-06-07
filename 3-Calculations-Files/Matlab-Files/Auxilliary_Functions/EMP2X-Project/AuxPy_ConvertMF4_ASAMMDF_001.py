#!/usr/bin/env python3
"""Convert MDF/MF4 channels to CSV using asammdf.

This helper is called by AuxFcn_ReadDAQ_MF4_ASAMMDF_001.m. It keeps Python
package handling outside MATLAB's data-conversion layer and writes a simple
CSV that MATLAB can read reliably.
"""

from __future__ import annotations

import argparse
import json
import re
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


def channel_unit_from_name(channel_name: str) -> str:
    """Extract a bracketed unit from a dataframe column name, if present."""
    match = re.search(r"\[([^\]]+)\]\s*$", channel_name)
    if match:
        return match.group(1).strip()
    return ""


def channel_base_name(channel_name: str) -> str:
    """Remove a trailing bracketed unit label from a channel name."""
    return re.sub(r"\s*\[[^\]]+\]\s*$", "", channel_name).strip()


def build_unit_lookup(mdf) -> dict[str, str]:
    """Build channel-name -> unit lookup from asammdf channel metadata."""
    lookup: dict[str, str] = {}
    channels_db = getattr(mdf, "channels_db", {}) or {}

    for channel_name, entries in channels_db.items():
        unit = ""
        for entry in entries:
            try:
                group_index, channel_index = entry[:2]
                signal = call_version_tolerant(
                    mdf.get,
                    name=channel_name,
                    group=group_index,
                    index=channel_index,
                )
                unit = str(getattr(signal, "unit", "") or "").strip()
            except Exception:
                unit = ""

            if unit:
                break

        if unit and channel_name not in lookup:
            lookup[str(channel_name)] = unit

    return lookup


def resolve_column_units(mdf, dataframe_columns: list[str]) -> list[str]:
    """Resolve one unit per dataframe signal column."""
    unit_lookup = build_unit_lookup(mdf)
    units: list[str] = []

    for column_name in dataframe_columns:
        bracket_unit = channel_unit_from_name(column_name)
        if bracket_unit:
            units.append(bracket_unit)
            continue

        base_name = channel_base_name(column_name)
        unit = unit_lookup.get(column_name, "") or unit_lookup.get(base_name, "")

        if not unit:
            try:
                signal = call_version_tolerant(mdf.get, name=base_name)
                unit = str(getattr(signal, "unit", "") or "").strip()
            except Exception:
                unit = ""

        units.append(unit)

    return units


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

    signal_columns = list(map(str, df.columns[1:]))
    channel_units = resolve_column_units(mdf, signal_columns)

    metadata = {
        "input": str(input_path),
        "group_index_zero_based": args.group_index,
        "read_mode": "all_groups_to_dataframe",
        "raster_s": raster,
        "columns": list(map(str, df.columns)),
        "channel_names": signal_columns,
        "channel_units": channel_units,
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
