classdef TransportFactory < handle
    %TRANSPORTFACTORY - Class for producing connectivity-specific
    % transport object

    % Copyright 2023 The MathWorks, Inc.

    methods(Static, Access = public)
        function transport = getTransport(connectionInfo)
            % Returns the transport layer object
            transport = matlabshared.bitalinolib.bluetooth.BluetoothTransport(connectionInfo);
        end
    end
end