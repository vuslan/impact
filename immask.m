function msk = immask(img,rect,th)
plgon = [repmat(rect(1:2)',1,5)] + [0 0 rect([3 3]) 0;0 rect([4 4]) 0 0];
rlgon = [cos(th) sin(th); -sin(th) cos(th)]*(plgon-rect(1:2)')+rect(1:2)';
[col,row] = meshgrid(1:size(img,2),1:size(img,1));
msk = inpolygon(col,row,rlgon(1,:),rlgon(2,:));
