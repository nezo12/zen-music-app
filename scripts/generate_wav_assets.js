const fs = require('fs');
const path = require('path');

const outDir = path.join(__dirname, '..', 'assets', 'audio');
fs.mkdirSync(outDir, { recursive: true });

const sampleRate = 22050;
const bitsPerSample = 16;
const channels = 1;

const songs = [
  {
    file: 'morning_focus.wav',
    notes: [261.63, 329.63, 392.0, 523.25, 392.0, 329.63],
    seconds: 18,
  },
  {
    file: 'night_drive.wav',
    notes: [196.0, 246.94, 293.66, 369.99, 293.66, 246.94],
    seconds: 18,
  },
  {
    file: 'soft_rain.wav',
    notes: [220.0, 277.18, 329.63, 440.0, 329.63, 277.18],
    seconds: 18,
  },
];

function writeWav(song) {
  const frameCount = sampleRate * song.seconds;
  const dataSize = frameCount * channels * (bitsPerSample / 8);
  const buffer = Buffer.alloc(44 + dataSize);

  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(channels, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(sampleRate * channels * (bitsPerSample / 8), 28);
  buffer.writeUInt16LE(channels * (bitsPerSample / 8), 32);
  buffer.writeUInt16LE(bitsPerSample, 34);
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);

  for (let i = 0; i < frameCount; i += 1) {
    const t = i / sampleRate;
    const beat = Math.floor(t / 1.5) % song.notes.length;
    const frequency = song.notes[beat];
    const fadeIn = Math.min(1, t / 1.2);
    const fadeOut = Math.min(1, (song.seconds - t) / 1.8);
    const envelope = Math.max(0, Math.min(fadeIn, fadeOut));
    const pad = Math.sin(2 * Math.PI * frequency * t) * 0.32;
    const shimmer = Math.sin(2 * Math.PI * frequency * 2 * t) * 0.08;
    const bass = Math.sin(2 * Math.PI * (frequency / 2) * t) * 0.12;
    const value = Math.max(-1, Math.min(1, (pad + shimmer + bass) * envelope));
    buffer.writeInt16LE(Math.round(value * 32767), 44 + i * 2);
  }

  fs.writeFileSync(path.join(outDir, song.file), buffer);
}

songs.forEach(writeWav);
console.log(`Generated ${songs.length} WAV files in ${outDir}`);
