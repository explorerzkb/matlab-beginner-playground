function playSoundCue(cue, cfg)
%PLAYSOUNDCUE Optional synthesized feedback; gameplay never depends on it.

if ~cfg.runtime.enableAudio || cfg.runtime.testMode
    return;
end
try
    sampleRate = 8000;
    switch cue
        case 'checkpoint'
            frequencies = [660, 880];
            duration = 0.08;
        case 'failure'
            frequencies = [220, 165];
            duration = 0.10;
        otherwise
            frequencies = 440;
            duration = 0.06;
    end
    signal = [];
    for frequency = frequencies
        t = 0:1/sampleRate:duration;
        envelope = linspace(1, 0, numel(t));
        signal = [signal, 0.10 * sin(2 * pi * frequency * t) .* envelope]; %#ok<AGROW>
    end
    sound(signal, sampleRate);
catch
    % Audio devices vary; silence must never stop the game.
end
end
