function acq = readC3DAcquisition(fileName)
%READC3DACQUISITION Open a C3D file with ezc3d.
%
%   Replacement for the former btkReadAcquisition call: ezc3d reads the
% file (see GETC3DREADER). Pass the result to GETC3DANALOGS and
% GETC3DMARKERS, which return the same layout btkGetAnalogs and
% btkGetMarkers did, and release it with CLOSEC3DACQUISITION.
%
%   Inputs:
%     fileName - path to a .c3d file
%
%   Outputs:
%     acq - struct with fields
%             reader   - 'ezc3d'
%             fileName - the file read
%             handle   - always empty (kept from the BTK version)
%             c3d      - struct returned by ezc3dRead
%
%   Toolbox Dependencies:
%     ezc3d - pyomeca C3D reader (fun/ext/ezc3d)
%
%   See also GETC3DREADER, GETC3DANALOGS, GETC3DMARKERS,
%   CLOSEC3DACQUISITION.

arguments
    fileName {mustBeTextScalar}
end

fileName = char(fileName);
if ~isfile(fileName)
    error('readC3DAcquisition:fileNotFound', ...
        'C3D file not found: %s', fileName);
end

acq = struct('reader', getC3DReader(), 'fileName', fileName, ...
    'handle', [], 'c3d', []);
acq.c3d = ezc3dRead(fileName);

end
