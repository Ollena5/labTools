function closeC3DAcquisition(acq)
%CLOSEC3DACQUISITION Release a C3D acquisition opened by READC3DACQUISITION.
%
%   Kept from the BTK version, where it freed the C++ memory BTK held
% for the acquisition. ezc3d data are ordinary MATLAB variables, so
% there is nothing to release and this does nothing.
%
%   Inputs:
%     acq - struct returned by READC3DACQUISITION
%
%   Outputs:
%     none
%
%   Toolbox Dependencies:
%     ezc3d (see READC3DACQUISITION)
%
%   See also READC3DACQUISITION.

arguments
    acq (1,1) struct %#ok<INUSA>
end

end
