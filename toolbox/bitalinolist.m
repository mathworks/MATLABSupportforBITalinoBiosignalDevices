function list = bitalinolist(options)
    %BITALINOLIST Scans nearby BITalino biosignal devices.
    %
    %   list = BITALINOLIST returns a table with information about nearby BITalino
    %   biosignal devices.
    %
    %   list = BITALINOLIST(Name, Value) returns the table using optional name-value
    %   pairs before scanning.
    %
    %   Examples:
    %       % Scans all nearby BITalino biosignal devices
    %       list = bitalinolist
    %
    %       % Scans nearby BITalino biosignal devices for specified time
    %       list = bitalinolist("Timeout", 10)
    %
    %   See also bitalino

    % Copyright 2023 The MathWorks, Inc.
    arguments
        % Validate timeout is within a minimum and maximum range and assign
        % a default value
        options.Timeout double {mustBeInteger, mustBeGreaterThanOrEqual(options.Timeout,3)} = 3
    end

    % BITalino is only supported on Windows and macOS
    matlabshared.bitalinolib.internal.Utility.validatePlatform();

    % Create an empty table for bitalinolist's output
    list = table(ones(0,1), strings(0,1), strings(0,1));
    list.Properties.VariableNames = ["Index", "Name", "Address"];

    % Avoid showing BLE specific warning for no device found
    warnState = warning('off','MATLAB:ble:ble:noDeviceWithNameFound');
    bitalinoDevices = blelist("Name","bitalino", Timeout=options.Timeout);
    % Restore the previous warning state for the user
    warning(warnState);

    if isempty(bitalinoDevices)
        % Avoid showing backtrace for warning
        backtraceState = warning('off', 'backtrace');
        warning(matlabshared.bitalinolib.internal.BitalinoConstants.BitalinoMessages.noDeviceFound);
        % Restore the previous backtrace state for the user
        warning(backtraceState);
        list = bitalinoDevices;
        return
    end
    % Remove variables not relevant for bitalinolist
    list = removevars(bitalinoDevices, ["RSSI","Advertisement"]);

    if ismac
        % Avoid showing incorrect BLE address in macOS till bitalinolist
        % uses bluetoothlist for scanning devices
        list.Address = repmat(missing, size(list.Address));
    end
end