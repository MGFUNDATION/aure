"""Genera sonidos ambientales sintéticos (libres de derechos) en bucle."""
import sys, wave, numpy as np
SR = 22050
D = 12  # segundos
out = sys.argv[1]
rng = np.random.default_rng(7)
n = SR * D
t = np.arange(n) / SR

def lowpass(x, a):
    y = np.empty_like(x); acc = 0.0
    for i in range(len(x)):
        acc += a * (x[i] - acc); y[i] = acc
    return y

def norm(x, peak=0.6):
    x = x - x.mean(); return x / (np.abs(x).max() + 1e-9) * peak

def loopify(x):
    # fundido cruzado para que el bucle no tenga corte
    f = SR // 2
    x = x.copy()
    ramp = np.linspace(0, 1, f)
    x[:f] = x[:f] * ramp + x[-f:] * (1 - ramp)
    return x[:-f]

white = rng.standard_normal(n)
# Lluvia: ruido rosado-ish + gotitas
rain = lowpass(white, 0.35) * 0.7 + white * 0.08
drops = np.zeros(n); idx = rng.integers(0, n - 200, 900)
for i in idx: drops[i:i+200] += rng.uniform(0.2, 1) * np.exp(-np.arange(200) / 25) * rng.standard_normal(200)
rain = norm(rain + drops * 0.5, 0.5)
# Viento: ruido marrón con ráfagas lentas
brown = np.cumsum(white); brown = brown - lowpass(brown, 0.0005)
wind = norm(lowpass(brown, 0.05) * (0.6 + 0.4 * np.sin(2*np.pi*t/6) ** 2), 0.5)
# Río: ruido filtrado con modulación rápida
river = norm(lowpass(white, 0.12) * (0.8 + 0.2 * np.sin(2*np.pi*t*3.1)), 0.45)
# Fogata: ruido grave + chasquidos
fire = lowpass(white, 0.02) * 2
pops = np.zeros(n); idx = rng.integers(0, n - 400, 140)
for i in idx: pops[i:i+400] += rng.uniform(0.3, 1) * np.exp(-np.arange(400) / 40) * rng.standard_normal(400)
fire = norm(fire + pops, 0.55)
# Pájaros: gorjeos con barridos de frecuencia sobre brisa suave
birds = lowpass(white, 0.03) * 0.3
for _ in range(45):
    s = rng.integers(0, n - SR); L = int(SR * rng.uniform(0.06, 0.18)); f0 = rng.uniform(2500, 4200)
    tt = np.arange(L) / SR
    sweep = f0 + rng.uniform(-1200, 1200) * tt / tt[-1]
    chirp = np.sin(2*np.pi*np.cumsum(sweep)/SR) * np.sin(np.pi*tt/tt[-1]) ** 2
    for k in range(rng.integers(1, 4)):
        o = s + k * int(L * 1.3)
        if o + L < n: birds[o:o+L] += chirp * rng.uniform(0.4, 0.9)
birds = norm(birds, 0.5)

for name, x in [('rain', rain), ('wind', wind), ('river', river), ('fire', fire), ('birds', birds)]:
    x = loopify(x)
    with wave.open(f'{out}/{name}.wav', 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((np.clip(x, -1, 1) * 32767).astype('<i2').tobytes())
    print(name, len(x) / SR, 's')
