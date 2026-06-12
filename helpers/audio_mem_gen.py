import numpy as np
import scipy.io.wavfile as wav
import scipy.signal as signal

def convert_wav_to_hex(in_path, out_path, samples=4410):
    sample_f, data = wav.read(in_path)
    
    if len(data.shape) > 1:
        data = data[:, 0]

    freq = 11025
    if sample_f != freq:
        sample_f2f = int(len(data) * (freq / sample_f))
        data = signal.resample(data, sample_f2f)

    if data.dtype == np.float32 or data.dtype == np.float64:
        data = np.int16(data * 32767)
    elif data.dtype == np.uint8:
        data = np.int16((data.astype(np.int32) - 128) * 256)
        
    if len(data) > samples:
        final_data = data[:samples]
    else:
        final_data = np.pad(data, (0, samples - len(data)), 'constant', constant_values=0)
        
    with open(out_path, 'w') as f:
        for sample in final_data:
            hex_val = format(int(sample) & 0xFFFF, '04X')
            f.write(f"{hex_val}\n")

convert_wav_to_hex("./pictrans/gunshot_raw.wav", "./final_proj/audio_gunshot.mem")
convert_wav_to_hex("./pictrans/death_raw.wav", "./final_proj/audio_death.mem")