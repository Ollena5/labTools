function getLabelsFromc3d()

[file,path] = uigetfile('*.c3d','Choose a .c3d file');

if file ~= 0                        % if file retrieved successfully, ...
    H = readC3DAcquisition([path file]);
    markers = getC3DMarkers(H);
end
markerLabels = fields(markers);
disp('The marker labels are: ');
disp(markerLabels);

end

