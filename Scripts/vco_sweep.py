#!/usr/bin/env python3
"""
Generate a 256-point 12-bit DAC LUT (Vref=3.3 V) for a frequency-linear sweep
from 2400 MHz to 2500 MHz on a MAX2750 VCO by inverting a cubic fit to the
datasheet tuning curve with edge slopes.

Model: f(V) = a*V^3 + b*V^2 + c*V + d
Constraints (MHz, MHz/V):
  f(0.4) = 2400
  f(2.4) = 2500
  f'(0.4) = 140
  f'(2.4) = 90
"""

from math import isfinite
import numpy as np

# ----------- Adjustable parameters -----------
N_POINTS   = 512              # LUT length (inclusive endpoints)
F_START    = 2400.0           # MHz
F_STOP     = 2500.0           # MHz
V_MIN      = 0.9              # V (manufacturer-guaranteed lower bound)
V_MAX      = 1.75              # V (manufacturer-guaranteed upper bound)
KV_LEFT    = 140.0            # MHz/V (small-signal slope near low end)
KV_RIGHT   = 90.0             # MHz/V (small-signal slope near high end)

DAC_BITS   = 12               # 12-bit DAC
VREF       = 3.3              # V
LINE_WRAP  = 16               # how many ints per line in the printed C array
ARRAY_NAME = "vtune_dac_lut"  # C array name
# --------------------------------------------

def fit_cubic_from_endpoint_slopes(v0, f0, k0, v1, f1, k1):
    """
    Solve for a,b,c,d in f(V) = a V^3 + b V^2 + c V + d
    given: f(v0)=f0, f'(v0)=k0, f(v1)=f1, f'(v1)=k1
    """
    A = np.array([
        [v0**3, v0**2, v0, 1.0],
        [3*v0**2, 2*v0, 1.0, 0.0],
        [v1**3, v1**2, v1, 1.0],
        [3*v1**2, 2*v1, 1.0, 0.0],
    ], dtype=float)
    y = np.array([f0, k0, f1, k1], dtype=float)
    a, b, c, d = np.linalg.solve(A, y)
    return a, b, c, d

def make_f_and_df(a, b, c, d):
    f  = lambda V: ((a*V + b)*V + c)*V + d
    df = lambda V: (3*a*V + 2*b)*V + c
    return f, df

def invert_monotonic(f, df, target_f, v_lo, v_hi, max_iter=50, tol=1e-9):
    """
    Safely invert monotonic f(V) ∈ [f(v_lo), f(v_hi)] using a
    Newton-Raphson step with bisection fallback.
    """
    # Initial guess: linear map by average slope
    V = v_lo + (target_f - f(v_lo)) * (v_hi - v_lo) / (f(v_hi) - f(v_lo))

    lo, hi = v_lo, v_hi
    f_lo, f_hi = f(lo), f(hi)

    for _ in range(max_iter):
        fV = f(V)
        if abs(fV - target_f) < tol:
            return V

        dV = df(V)
        newton_ok = isfinite(dV) and abs(dV) > 1e-12
        if newton_ok:
            Vn = V - (fV - target_f) / dV
        else:
            Vn = np.nan

        # Keep brackets updated
        if fV < target_f:
            lo, f_lo = V, fV
        else:
            hi, f_hi = V, fV

        # If Newton step goes out of bounds, bisect
        if not isfinite(Vn) or (Vn <= lo) or (Vn >= hi):
            V = 0.5*(lo + hi)
        else:
            V = Vn

    # Fallback (should not happen if f is well-behaved and monotonic)
    return max(v_lo, min(v_hi, V))

def quantize_to_dac(V, vref, bits):
    code = int(round(V / vref * ((1 << bits) - 1)))
    return max(0, min((1 << bits) - 1, code))

def format_c_array(ints, name="lut", per_line=16):
    lines = []
    for i in range(0, len(ints), per_line):
        chunk = ", ".join(f"{x:5d}" for x in ints[i:i+per_line])
        lines.append("    " + chunk)
    return (
        f"static const uint16_t {name}[{len(ints)}] = {{\n" +
        ",\n".join(lines) +
        "\n};"
    )

# ---- Build the model and invert it ----
a, b, c, d = fit_cubic_from_endpoint_slopes(
    V_MIN, F_START, KV_LEFT,
    V_MAX, F_STOP,  KV_RIGHT
)
f, df = make_f_and_df(a, b, c, d)

# Sanity: ensure monotonic increasing in [V_MIN, V_MAX]
assert f(V_MIN) <= f(V_MAX) + 1e-6, "Model not monotonic as expected."

# Frequency-linear sweep
freqs = np.linspace(F_START, F_STOP, N_POINTS)

# Invert to get Vtune per frequency, then quantize to DAC codes
vtunes = [invert_monotonic(f, df, F, V_MIN, V_MAX) for F in freqs]
codes  = [quantize_to_dac(V, VREF, DAC_BITS) for V in vtunes]

# ---- Print results ----
print("// Cubic coefficients for f(V) = a V^3 + b V^2 + c V + d  (MHz, V)")
print(f"// a={a:.9f}, b={b:.9f}, c={c:.9f}, d={d:.9f}")
print(f"// Check: f({V_MIN})={f(V_MIN):.3f} MHz, f'({V_MIN})={df(V_MIN):.3f} MHz/V")
print(f"//        f({V_MAX})={f(V_MAX):.3f} MHz, f'({V_MAX})={df(V_MAX):.3f} MHz/V")
print(f"// VREF={VREF:.3f} V, DAC bits={DAC_BITS}, points={N_POINTS}")
print()
print(format_c_array(codes, name=ARRAY_NAME, per_line=LINE_WRAP))

# Optional: also dump the voltages alongside codes
# for i, (F, V, code) in enumerate(zip(freqs, vtunes, codes)):
#     print(f"{i:3d}, {F:.3f} MHz, Vtune={V:.6f} V, code={code}")
