function feature = poseFeatures(points, imageSize, cfg)
%POSEFEATURES Anatomical COCO joints in fixed, unmirrored camera pixels.
feature = struct('valid',false,'controlPose',false,'centre',[NaN NaN], ...
    'scale',NaN,'angle',NaN,'hip',NaN,'ankle',NaN);
if ~isequal(size(points),[17 3]), return; end
needed = [6:13 16 17];
if any(~isfinite(points(needed,:)),'all') || ...
        any(points(needed,3)<cfg.confidence), return; end
p = points(:,1:2);
if any(p(needed,1)<0 | p(needed,1)>imageSize(2)) || ...
        any(p(needed,2)<0 | p(needed,2)>imageSize(1)), return; end
shoulder = mean(p(6:7,:),1); hip = mean(p(12:13,:),1);
% The lower ankle must rise too: lifting just one foot is not a jump.
ankle = [mean(p(16:17,1)),max(p(16:17,2))];
scale = ankle(2)-shoulder(2);
if scale<0.25*imageSize(1), return; end
feature.valid = true;
feature.centre = hip./[imageSize(2) imageSize(1)];
feature.scale = scale;
feature.hip = hip(2);
feature.ankle = ankle(2);
% Raw frontal camera: anatomical right elbow is on image left.
% Right elbow DOWN yields positive (game right), independent of preview.
feature.angle = atan2d(p(9,2)-p(8,2),abs(p(9,1)-p(8,1)));
wrists = p(10:11,:); elbows = p(8:9,:);
torso = max(hip(2)-shoulder(2),0.15*scale);
feature.controlPose = all(wrists(:,2)<hip(2)-0.12*torso) && ...
    all(wrists(:,2)>shoulder(2)-0.30*scale) && ...
    all(abs(wrists(:,1)-shoulder(1))<0.32*scale) && ...
    norm(wrists(1,:)-wrists(2,:))<0.30*scale && ...
    abs(elbows(1,1)-elbows(2,1))>0.25*scale && ...
    all(elbows(:,2)<hip(2)+0.08*scale);
end
