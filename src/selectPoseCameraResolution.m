function resolution = selectPoseCameraResolution(available, preferred)
%SELECTPOSECAMERARESOLUTION Prefer 640x480 but accept device-specific modes.
available=cellstr(string(available));
if isempty(available)
    resolution='';
    return;
end
preferred=char(string(preferred));
match=find(strcmpi(available,preferred),1);
if ~isempty(match)
    resolution=available{match};
    return;
end

target=parseResolution(preferred);
scores=inf(size(available));
for i=1:numel(available)
    candidate=parseResolution(available{i});
    if all(isfinite(candidate))
        % Prefer a similar pixel workload and aspect ratio instead of the
        % largest advertised mode, which adds camera latency before resize.
        scores(i)=sum(abs(log(candidate./target))) + ...
            0.5*abs(log((candidate(1)/candidate(2))/(target(1)/target(2))));
    end
end
[score,index]=min(scores);
if ~isfinite(score), resolution=available{1};
else, resolution=available{index};
end
end

function sizeValue=parseResolution(value)
parts=sscanf(lower(char(value)),'%dx%d');
if numel(parts)~=2 || any(parts<=0), sizeValue=[NaN NaN];
else, sizeValue=double(parts(:))';
end
end
