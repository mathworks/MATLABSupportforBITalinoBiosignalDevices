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

    % Copyright 2023-2024 The MathWorks, Inc.
    arguments
        % Validate timeout is within a minimum and maximum range and assign
        % a default value
        options.Timeout double {mustBeInteger, mustBeGreaterThanOrEqual(options.Timeout,5)} = 5
    end

    % BITalino is only supported on Windows and macOS
    matlabshared.bitalinolib.internal.Utility.validatePlatform();

    % Create an empty table for bitalinolist's output
    list = table(ones(0,1), strings(0,1), strings(0,1));
    list.Properties.VariableNames = ["Index", "Name", "Address"];

    % Scan for BLE based BITalino devices then Bluetooth Classic based
    % BITalino devices. This way we are speeding up the scanning for
    % devices supporting both BLE and Bluetooth Classic.
    % Currently, if there are both types of devices in vicinity only BLE
    % based devices will show-up in the output of bitalinolist.

    % Avoid showing BLE specific warning for no device found
    btWarnState = warning('off','MATLAB:ble:ble:noDeviceWithNameFound');
    bitalinoDevices = blelist("Name","bitalino", Timeout=options.Timeout);
    % Restore the previous warning state for the user
    warning(btWarnState);

    if ~isempty(bitalinoDevices)
        % Remove variables not relevant for bitalinolist
        list = removevars(bitalinoDevices, ["RSSI","Advertisement"]);
    
        if ismac
            % Avoid showing incorrect BLE address in macOS till bitalinolist
            % uses bluetoothlist for scanning devices
            list.Address = repmat(missing, size(list.Address));
        end
        return
    end

    % Check if any BITalino devices supporting only Bluetooth classic is
    % available when there is no BLE enabled device
 
    % Avoid showing Bluetooth specific warning for no device found
    btWarnState = warning('off','MATLAB:bluetooth:bluetoothlist:noDeviceFound');
    btlist = bluetoothlist();
    % Restore the previous warning state for the user
    warning(btWarnState)
    

    if isempty(btlist) || ~any(contains(btlist.Name, "BITalino"))
        % Avoid showing backtrace for warning
        backtraceState = warning('off', 'backtrace');
        warning(matlabshared.bitalinolib.internal.BitalinoConstants.BitalinoMessages.noDeviceFound);
        % Restore the previous backtrace state for the user
        warning(backtraceState);
        list = bitalinoDevices;
    else
        % Found BITalino devices supporting only Bluetooth classic
        bitalinoDevices = removevars(btlist, ["Channel","Status"]);
        bitalinoIndex = contains(bitalinoDevices.Name, "BITalino");
        bitalinoDevices = bitalinoDevices(bitalinoIndex, :);
        index = table((1:height(bitalinoDevices))',VariableNames="Index");
        list = [index, bitalinoDevices];
    end
end