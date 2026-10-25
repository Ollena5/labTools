function reader = getC3DReader()
%GETC3DREADER Name of the C3D reader, after making ezc3d callable.
%
%   ezc3d is the only C3D reader. Its MATLAB binaries ship in
% fun/ext/ezc3d (one file per platform), and the copy there takes
% precedence over any other ezc3dRead on the MATLAB path. Its output is
% converted to the layout BTK used to return (see GETC3DANALOGS,
% GETC3DMARKERS). Errors if the binary for this platform is missing.
%
%   Inputs:
%     none
%
%   Outputs:
%     reader - 'ezc3d'
%
%   Toolbox Dependencies:
%     ezc3d (fun/ext/ezc3d)
%
%   See also READC3DACQUISITION, GETC3DANALOGS, GETC3DMARKERS.

%% Reject the Removed BTK Preference
% BTK was the default reader before ezc3d replaced it. Fail loudly rather
% than silently reading with ezc3d when a preference still asks for BTK.
if ispref('labTools', 'c3dReader') && ...
        strcmpi(getpref('labTools', 'c3dReader'), 'btk')
    error('getC3DReader:btkRemoved', ['Preference labTools/c3dReader ' ...
        'is ''btk'', but BTK is no longer a C3D reader in labTools. ' ...
        'Remove it with rmpref(''labTools'', ''c3dReader'').']);
end

%% Make the Bundled ezc3d Callable
addEzc3dToPath();
reader = 'ezc3d';

end

function addEzc3dToPath()
%ADDEZC3DTOPATH Put the bundled ezc3dRead first on the MATLAB path.
%
%   Uses only fun/ext/ezc3d of this labTools copy, so an older ezc3dRead
% elsewhere on the path cannot shadow it. Errors, naming the missing
% file and the computer architecture, if there is no binary for this
% platform.
%
%   Inputs:
%     none
%
%   Outputs:
%     none

labToolsRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
ezc3dFolder  = fullfile(labToolsRoot, 'fun', 'ext', 'ezc3d');
ezc3dFile    = fullfile(ezc3dFolder, ['ezc3dRead.' mexext()]);
if ~isfile(ezc3dFile)
    error('getC3DReader:noReader', ['The ezc3d binary for this ' ...
        'platform is missing: %s\nThis computer is %s (MEX extension ' ...
        '.%s). The official ezc3d 1.7.2 MATLAB binaries for Windows, ' ...
        'macOS and Linux are listed in %s.'], ezc3dFile, ...
        computer('arch'), mexext(), fullfile(ezc3dFolder, ...
        'ATTRIBUTION.md'));
end
if ~strcmpi(which('ezc3dRead'), ezc3dFile)
    addpath(ezc3dFolder, '-begin');
end

end
