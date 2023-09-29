classdef LastConnectionInfo
    %LASTCONNECTIONINFO - Static class that updates MATLAB preference with the
    %last BITalino device connection information.

    % Copyright 2023 The MathWorks, Inc.

    properties(Constant, Access = private)
        Group = "MATLAB_HARDWARE"
        Pref  = "BITALINO"
    end

    methods(Static, Access = public, Hidden)
        function info = get()
            % Get current preference value, return empty if none exists

            isPref = ispref(matlabshared.bitalinolib.internal.LastConnectionInfo.Group, matlabshared.bitalinolib.internal.LastConnectionInfo.Pref);
            info = [];
            if isPref
                info = getpref(matlabshared.bitalinolib.internal.LastConnectionInfo.Group, matlabshared.bitalinolib.internal.LastConnectionInfo.Pref);
            end
        end

        function set(name, address)
            % Add new preference if none exists or update existing
            % preference with specified values

            newPref.Name = name;
            newPref.Address = address;

            isPref = ispref(matlabshared.bitalinolib.internal.LastConnectionInfo.Group, matlabshared.bitalinolib.internal.LastConnectionInfo.Pref);
            if isPref
                setpref(matlabshared.bitalinolib.internal.LastConnectionInfo.Group, matlabshared.bitalinolib.internal.LastConnectionInfo.Pref, newPref);
            else
                addpref(matlabshared.bitalinolib.internal.LastConnectionInfo.Group, matlabshared.bitalinolib.internal.LastConnectionInfo.Pref, newPref);
            end
        end
    end
end