function checkC3DReader(c3dFile, detail)
%CHECKC3DREADER Print a C3D reader summary to compare across computers.
%
%   Reads one C3D file through the labTools reader (READC3DACQUISITION,
% GETC3DANALOGS, GETC3DMARKERS) and prints two blocks of lines. The ENV
% lines describe the computer and differ between machines. The DATA
% lines describe what the reader returned and must be identical on every
% platform for the same file: sizes, rates, SHA-256 digests of the
% channel and marker labels, of the unit strings (UTF-8 encoded, so a
% platform that decodes a character such as the 2 in mm/s^2 differently
% is caught), and of the raw bytes of every analog channel and marker.
%
%   To compare two computers, save the output on each and diff the DATA
% lines only, e.g. on macOS or Linux:
%     diff <(grep '^DATA' windows.txt) <(grep '^DATA' mac.txt)
%
%   Inputs:
%     c3dFile - path to a .c3d file
%     detail  - true also prints the digest of every analog channel and
%               marker, to locate a mismatch (default false)
%
%   Outputs:
%     none (prints to the Command Window)
%
%   Toolbox Dependencies:
%     ezc3d (see READC3DACQUISITION)
%
%   See also READC3DACQUISITION, GETC3DANALOGS, GETC3DMARKERS.

arguments
    c3dFile {mustBeTextScalar}
    detail (1,1) logical = false
end

c3dFile = char(c3dFile);
if ~isfile(c3dFile)
    error('checkC3DReader:fileNotFound', 'C3D file not found: %s', ...
        c3dFile);
end
readChunkBytes = 2^26;   % bytes per fread while hashing the C3D file
shownChannels  = 3;      % per-channel digests shown without detail
shortHashChars = 16;     % hex characters of a per-channel digest shown

%% Describe the Computer (ENV)
ezc3dMex = which('ezc3dRead');
fprintf('ENV  matlab                 %s\n', version());
fprintf('ENV  arch                   %s\n', computer('arch'));
fprintf('ENV  mexext                 %s\n', mexext());
fprintf('ENV  ezc3dRead              %s\n', ezc3dMex);
if ~isempty(ezc3dMex)
    fprintf('ENV  ezc3dRead sha256       %s\n', hashFile(ezc3dMex, ...
        readChunkBytes));
end
btkPath = which('btkReadAcquisition');
if isempty(btkPath)
    btkPath = '(none)';
end
fprintf('ENV  btkReadAcquisition     %s\n', btkPath);

%% Read the File Through the Reader
acq = readC3DAcquisition(c3dFile);
[analogs, analogsInfo] = getC3DAnalogs(acq);
[markers, markersInfo] = getC3DMarkers(acq);
closeC3DAcquisition(acq);

%% Sizes and Rates (DATA)
[~, fileName, fileExt] = fileparts(c3dFile);
fileInfo    = dir(c3dFile);
analogNames = fieldnames(analogs);
markerNames = fieldnames(markers);
nAnalog     = numel(analogNames);
nMarker     = numel(markerNames);
nSamples    = 0;
nFrames     = 0;
if nAnalog > 0
    nSamples = size(analogs.(analogNames{1}), 1);
end
if nMarker > 0
    nFrames = size(markers.(markerNames{1}), 1);
end
fprintf('DATA file                   %s%s\n', fileName, fileExt);
fprintf('DATA file bytes             %d\n', fileInfo.bytes);
fprintf('DATA file sha256            %s\n', hashFile(c3dFile, ...
    readChunkBytes));
fprintf('DATA analog channels        %d\n', nAnalog);
fprintf('DATA analog samples         %d\n', nSamples);
fprintf('DATA analog rate (Hz)       %.17g\n', analogsInfo.frequency);
fprintf('DATA markers                %d\n', nMarker);
fprintf('DATA marker frames          %d\n', nFrames);
fprintf('DATA marker rate (Hz)       %.17g\n', markersInfo.frequency);

%% Labels and Units (DATA)
analogLabels = struct2cell(analogsInfo.label);
analogUnits  = struct2cell(analogsInfo.units);
fprintf('DATA analog field names     %s\n', hashText(analogNames));
fprintf('DATA analog raw labels      %s\n', hashText(analogLabels));
fprintf('DATA marker field names     %s\n', hashText(markerNames));
fprintf('DATA analog units           %s\n', hashText(analogUnits));
fprintf('DATA marker units           %s\n', hashText( ...
    {markersInfo.units.ALLMARKERS}));
unitText = [analogUnits(:); {markersInfo.units.ALLMARKERS}];
nonAscii = unique(unitText(cellfun(@(txt) any(double(txt) > 127), ...
    unitText)));
for ii = 1:numel(nonAscii)
    fprintf('DATA non-ASCII unit %d       code points %s\n', ii, ...
        strjoin(arrayfun(@(cp) sprintf('U+%04X', cp), ...
        double(nonAscii{ii}), 'UniformOutput', false), ' '));
end

%% Value Digests (DATA)
[analogDigest, analogEach] = digestFields(analogs);
[markerDigest, markerEach] = digestFields(markers);
fprintf('DATA analog values sha256   %s\n', analogDigest);
fprintf('DATA marker values sha256   %s\n', markerDigest);
fprintf('DATA analog min / max       %.17g / %.17g\n', ...
    fieldExtreme(analogs, @min), fieldExtreme(analogs, @max));
fprintf('DATA marker min / max       %.17g / %.17g\n', ...
    fieldExtreme(markers, @min), fieldExtreme(markers, @max));
nShownAnalog = nAnalog;
nShownMarker = nMarker;
if ~detail
    nShownAnalog = min(nAnalog, shownChannels);
    nShownMarker = min(nMarker, shownChannels);
end
for ii = 1:nShownAnalog
    fprintf('DATA analog %-18s %s\n', analogNames{ii}, ...
        analogEach{ii}(1:shortHashChars));
end
for ii = 1:nShownMarker
    fprintf('DATA marker %-18s %s\n', markerNames{ii}, ...
        markerEach{ii}(1:shortHashChars));
end

end

function [combined, each] = digestFields(data)
%DIGESTFIELDS SHA-256 of the raw bytes of every field of a struct.
%
%   Inputs:
%     data - struct of numeric arrays
%
%   Outputs:
%     combined - hex digest over all fields in field order
%     each     - cell array with the hex digest of each field

names = fieldnames(data);
total = java.security.MessageDigest.getInstance('SHA-256');
each  = cell(numel(names), 1);
for ii = 1:numel(names)
    values = data.(names{ii});
    bytes  = typecast(double(values(:)), 'int8');
    one    = java.security.MessageDigest.getInstance('SHA-256');
    one.update(bytes);
    total.update(bytes);
    each{ii} = digestToHex(one.digest());
end
combined = digestToHex(total.digest());

end

function extreme = fieldExtreme(data, fcn)
%FIELDEXTREME Smallest or largest finite-or-not value across a struct.
%
%   Inputs:
%     data - struct of numeric arrays
%     fcn  - @min or @max
%
%   Outputs:
%     extreme - value of FCN over all fields, ignoring NaN (NaN if none)

names   = fieldnames(data);
extreme = NaN;
for ii = 1:numel(names)
    values  = data.(names{ii});
    extreme = fcn([extreme; fcn(values(:), [], 'omitnan')], [], ...
        'omitnan');
end

end

function hex = hashText(textList)
%HASHTEXT SHA-256 of a cell array of strings, UTF-8 encoded.
%
%   Inputs:
%     textList - cell array of char vectors
%
%   Outputs:
%     hex - hex digest of the strings joined by line feeds

joined = strjoin(textList(:)', newline);
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(typecast(unicode2native(joined, 'UTF-8'), 'int8'));
hex = digestToHex(md.digest());

end

function hex = hashFile(fileName, chunkBytes)
%HASHFILE SHA-256 of a file, read in chunks.
%
%   Inputs:
%     fileName   - path to the file
%     chunkBytes - number of bytes to read at a time
%
%   Outputs:
%     hex - hex digest of the file contents

md  = java.security.MessageDigest.getInstance('SHA-256');
fid = fopen(fileName, 'r');
closeFile = onCleanup(@() fclose(fid));
while ~feof(fid)
    chunk = fread(fid, chunkBytes, '*uint8');
    md.update(typecast(chunk, 'int8'));
end
hex = digestToHex(md.digest());

end

function hex = digestToHex(digestBytes)
%DIGESTTOHEX Lower-case hex string of a Java digest (int8 array).
%
%   Inputs:
%     digestBytes - int8 array returned by MessageDigest.digest
%
%   Outputs:
%     hex - hex string, two characters per byte

hex = lower(reshape(dec2hex(typecast(digestBytes, 'uint8'), 2).', 1, []));

end
