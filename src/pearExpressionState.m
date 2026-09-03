function face = pearExpressionState(player, ropeDirection, ropeTension)
%PEAREXPRESSIONSTATE Select a readable face without changing physics.

if nargin < 2 || numel(ropeDirection) ~= 2
    ropeDirection = [0, 0];
end
if nargin < 3
    ropeTension = 0;
end

impactTimer = 0;
if isfield(player, 'visualImpactTimer')
    impactTimer = player.visualImpactTimer;
end

if impactTimer > 0
    face.name = 'pain';
elseif ropeTension > 1.5
    face.name = 'pulled';
elseif ~player.onGround && player.vel(2) > 1.6
    face.name = 'joy';
elseif ~player.onGround && player.vel(2) < -3.2
    face.name = 'surprised';
elseif abs(player.moveIntent) > 0.1
    face.name = 'playful';
else
    face.name = 'curious';
end

directionLength = hypot(ropeDirection(1), ropeDirection(2));
if ropeTension > 0.25 && directionLength > 1e-9
    face.gaze = 0.075 * ropeDirection / directionLength;
elseif abs(player.vel(1)) > 0.6
    face.gaze = [0.035 * sign(player.vel(1)), 0];
else
    face.gaze = [0, 0.01];
end
end
