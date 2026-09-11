function feature = poseFeatures(points, imageSize, cfg)
%POSEFEATURES Upper-body COCO joints in fixed, unmirrored camera pixels.
feature = struct('valid',false,'controlPose',false,'centre',[NaN NaN], ...
    'scale',NaN,'angle',NaN,'bodyY',NaN,'headY',NaN,'headGap',NaN);
if ~isequal(size(points),[17 3]), return; end
% Nose, shoulders, elbows and wrists are the complete required framing.
% Hips, knees and ankles may all be outside the camera image.
needed = [1 6:11];
if any(~isfinite(points(needed,:)),'all') || ...
        any(points(needed,3)<cfg.confidence), return; end
p = points(:,1:2);
if any(p(needed,1)<0 | p(needed,1)>imageSize(2)) || ...
        any(p(needed,2)<0 | p(needed,2)>imageSize(1)), return; end
shoulder = mean(p(6:7,:),1);
scale = norm(p(6,:)-p(7,:));
if scale<cfg.minimumShoulderPixels, return; end
feature.valid = true;
feature.centre = shoulder./[imageSize(2) imageSize(1)];
feature.scale = scale;
feature.bodyY = shoulder(2);
feature.headY = p(1,2);
feature.headGap = shoulder(2)-p(1,2);
% Raw frontal camera: anatomical right elbow is on image left.
% Right elbow DOWN yields positive (game right), independent of preview.
feature.angle = atan2d(p(9,2)-p(8,2),abs(p(9,1)-p(8,1)));
wrists = p(10:11,:); elbows = p(8:9,:);
feature.controlPose = all(wrists(:,2)>shoulder(2)-0.45*scale) && ...
    all(wrists(:,2)<shoulder(2)+1.35*scale) && ...
    all(abs(wrists(:,1)-shoulder(1))<0.85*scale) && ...
    norm(wrists(1,:)-wrists(2,:))<0.65*scale && ...
    abs(elbows(1,1)-elbows(2,1))>0.90*scale && ...
    all(elbows(:,2)>shoulder(2)-0.50*scale) && ...
    all(elbows(:,2)<shoulder(2)+1.25*scale) && ...
    feature.headGap>0.25*scale && feature.headGap<1.60*scale;
end
