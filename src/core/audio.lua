-- Procedural audio: all sound effects and the music loop are synthesized
-- in code (no audio files). Volume layers: master / sfx / music.
local utils = require("src.core.utils")

local audio = {
    sounds = {}, sources = {}, musicSource = nil,
    sampleRate = 44100,
    masterVol = 1.0, sfxVol = 1.0, musicVol = 0.4,
    musicEnabled = true,
}

local function sine(t, f) return math.sin(t * f * math.pi * 2) end
local function square(t, f) return sine(t, f) > 0 and 1 or -1 end
local function sawtooth(t, f) return 2 * ((t * f) % 1) - 1 end
local function noise() return math.random() * 2 - 1 end

local function makeSoundData(duration, generator)
    local samples = math.floor(duration * audio.sampleRate)
    local sd = love.sound.newSoundData(samples, audio.sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / audio.sampleRate
        sd:setSample(i, math.max(-1, math.min(1, generator(t, i, samples))))
    end
    return sd
end

function audio.init()
    math.randomseed(os.time())
    audio.sounds.click = makeSoundData(0.08, function(t) return square(t, 1200) * math.exp(-t * 60) * 0.4 end)
    audio.sounds.shoot = makeSoundData(0.12, function(t) return sawtooth(t, 600 + t * 2000) * math.exp(-t * 25) * 0.35 end)
    audio.sounds.explosion = makeSoundData(0.35, function(t) return noise() * math.exp(-t * 12) * 0.5 end)
    audio.sounds.hit = makeSoundData(0.06, function(t) return noise() * math.exp(-t * 80) * 0.3 end)
    audio.sounds.powerup = makeSoundData(0.25, function(t) return (sine(t, 440 + t * 1200) + sine(t, 660 + t * 800)) * math.exp(-t * 8) * 0.25 end)
    audio.sounds.levelup = makeSoundData(0.6, function(t)
        local notes = {523, 659, 784, 1047}
        local idx = math.min(4, math.floor(t * 6) + 1)
        return sine(t, notes[idx] or 1047) * math.exp(-(t % 0.15) * 20) * 0.3
    end)
    audio.sounds.achievement = makeSoundData(0.8, function(t)
        local scale = {523, 587, 659, 784, 880, 1047, 1175, 1319}
        local idx = math.min(#scale, math.floor(t * 10) + 1)
        return sine(t, scale[idx] or 1319) * math.exp(-(t % 0.08) * 30) * 0.25
    end)
    audio.sounds.gameover = makeSoundData(1.0, function(t) return sine(t, 800 - t * 600) * math.exp(-t * 3) * 0.3 end)
    audio.sounds.music = audio.generateMusic()
    audio.startMusic()
end

-- Drop finished one-shot sources so the pool cannot grow without bound.
-- (LÖVE 11.5 removed Source:isStopped; "not isPlaying" is equivalent here
-- because one-shot sounds are never paused.)
function audio.update()
    for i = #audio.sources, 1, -1 do
        local src = audio.sources[i]
        if not src:isPlaying() then table.remove(audio.sources, i) end
    end
end

function audio.generateMusic()
    local duration = 4.0
    local samples = math.floor(duration * audio.sampleRate)
    local sd = love.sound.newSoundData(samples, audio.sampleRate, 16, 1)
    local bpm = 128
    local beat = 60 / bpm
    for i = 0, samples - 1 do
        local t = i / audio.sampleRate
        local s = 0
        local kp = (t % beat) / beat
        if kp < 0.08 then s = s + sine(t, 80 * math.exp(-kp * 20)) * math.exp(-kp * 40) * 0.4 end
        local sn = math.floor(t / beat) % 4
        if sn == 1 or sn == 3 then
            local sp = (t % beat) / beat
            if sp < 0.06 then s = s + noise() * math.exp(-sp * 35) * 0.2 end
        end
        local hp = (t % (beat / 2)) / (beat / 2)
        if hp < 0.03 then s = s + noise() * math.exp(-hp * 60) * 0.08 end
        local bassNotes = {55, 55, 65, 49, 55, 55, 73, 49}
        local bi = math.floor(t / beat) % 8 + 1
        s = s + sine(t, bassNotes[bi] or 55) * 0.12
        if t % (beat * 2) > beat then
            local arp = {523, 659, 784, 1047}
            local ai = math.floor(t / (beat / 2)) % 4 + 1
            s = s + sine(t, arp[ai] or 523) * 0.04
        end
        sd:setSample(i, math.max(-1, math.min(1, s)))
    end
    return sd
end

function audio.startMusic()
    if audio.musicSource then audio.musicSource:stop() end
    if audio.sounds.music then
        audio.musicSource = love.audio.newSource(audio.sounds.music, "static")
        audio.musicSource:setLooping(true)
        audio.musicSource:setVolume(audio.musicVol * audio.masterVol)
        if audio.musicEnabled then audio.musicSource:play() end
    end
end

function audio.play(name)
    if not audio.sounds[name] then return end
    local src = love.audio.newSource(audio.sounds[name], "static")
    src:setVolume(audio.sfxVol * audio.masterVol)
    src:play()
    audio.sources[#audio.sources + 1] = src
end

function audio.setMasterVolume(v) audio.masterVol = utils.clamp(v, 0, 1); audio.updateVolumes() end
function audio.setSfxVolume(v) audio.sfxVol = utils.clamp(v, 0, 1) end
function audio.setMusicVolume(v) audio.musicVol = utils.clamp(v, 0, 1); audio.updateVolumes() end

function audio.updateVolumes()
    if audio.musicSource then audio.musicSource:setVolume(audio.musicVol * audio.masterVol) end
end

function audio.toggleMusic()
    audio.musicEnabled = not audio.musicEnabled
    if audio.musicSource then
        if audio.musicEnabled then audio.musicSource:play() else audio.musicSource:pause() end
    end
end

function audio.stopMusic() if audio.musicSource then audio.musicSource:stop() end end

return audio
