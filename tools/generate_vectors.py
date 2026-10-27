from pathlib import Path
from random import Random

threshould = 1_000_000
required = 4

root = Path(__file__).resolve().parents[1]
output = root / "vectors" / "pulse_vectors.txt"


def main():
    rng = Random(42)

    # Each sample contains: reset_n, valid, I, Q.
    samples = [
        (0, 0, 0, 0),
        (0, 0, 0, 0),
    ]

    # Low-power noise should not trigger detection.
    for _ in range(8):
        samples.append((
            1, 1,
            rng.randint(-250, 250),
            rng.randint(-250, 250),
        ))

    samples.extend([
        (1, 1, 1400, 0),     # Single spike: reject.
        (1, 1, 0, 0),
        (1, 1, 100, -150),

        (1, 1, 1100, 0),     # Sustained pulse begins.
        (1, 1, 1300, 0),
        (1, 1, 1500, 0),
        (1, 1, 1800, 0),     # Fourth sample: detect.
        (1, 1, 1700, 100),   # Same pulse: no new event.

        (1, 1, 0, 0),        # Rearm.
        (1, 1, 0, 0),

        (1, 1, 1200, 0),     # Three-sample pulse: reject.
        (1, 1, 1250, 0),
        (1, 1, 1400, 0),
        (1, 1, 0, 0),

        (1, 1, -1100, 0),    # Negative inputs.
        (1, 1, -1300, 0),
        (1, 1, 0, -1500),
        (1, 1, -1700, -200), # Fourth sample: detect.
        (1, 1, 0, 0),
    ])

    # Maximum-magnitude negative 12-bit inputs.
    samples.extend([
        (1, 1, -2048, -2048),
        (1, 1, -2048, -2048),
        (1, 1, -2048, -2048),
        (1, 1, -2048, -2048),
        (1, 1, 0, 0),
    ])

    high_count = 0
    in_pulse = False
    candidate_peak = 0
    peak_power = 0
    rows = []

    # Calculate expected results independently in Python.
    for reset_n, valid, i, q in samples:
        detected = 0

        if not reset_n:
            high_count = 0
            in_pulse = False
            candidate_peak = 0
            peak_power = 0

        elif valid:
            power = i * i + q * q

            if power >= threshould:
                if in_pulse:
                    peak_power = max(peak_power, power)
                else:
                    if high_count == 0:
                        candidate_peak = power
                    else:
                        candidate_peak = max(candidate_peak, power)

                    high_count += 1

                    if high_count == required:
                        detected = 1
                        in_pulse = True
                        high_count = 0
                        peak_power = candidate_peak
            else:
                high_count = 0
                in_pulse = False
                candidate_peak = 0

        # Encode signed inputs as 12-bit hexadecimal values.
        rows.append(
            f"{reset_n} {valid} "
            f"{i & 0xFFF:03X} {q & 0xFFF:03X} "
            f"{detected} {peak_power:07X}"
        )

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(rows) + "\n", encoding="ascii")

    print(f"Wrote {len(rows)} vectors to {output}")


if __name__ == "__main__":
    main()