classdef BluetoothTransport < matlabshared.bitalinolib.internal.TransportBase
    %BLUETOOTHTRANSPORT Bluetooth Classic transport class to communicate
    % with BITalino

    % Copyright 2023-2024 The MathWorks, Inc.
    properties (Access = private)
        % Bluetooth Classic transport layer object
        BluetoothDevice
        % Number of bytes to read from BITalino
        NumBytesToRead
    end

    methods
        function obj = BluetoothTransport(connectionInfo)
            import matlabshared.bitalinolib.internal.BitalinoConstants

            obj@matlabshared.bitalinolib.internal.TransportBase;
            try
                if isempty(connectionInfo)
                    % If bitalino was called without name or address try to
                    % connect to the last successfully connected device or
                    % the first device available in bitalinolist
                    deviceInfo = matlabshared.bitalinolib.internal.LastConnectionInfo.get();
                    warnState = warning('off');
                    list = bitalinolist();
                    warning(warnState);
                    if isempty(deviceInfo) && isempty(list)
                        % No connection was made earlier and no device
                        % detected
                        error(BitalinoConstants.BitalinoMessages.failedConnect);
                    elseif ~isempty(deviceInfo)
                        % Connect to the last successfully connected device
                        availableDeviceName = deviceInfo.Name;
                    else
                        % Connect to first device available in bitalinolist
                        availableDeviceName = list.Name(1);
                    end
                    % constructor called without device name or address
                    obj.BluetoothDevice = bluetooth(availableDeviceName);
                else
                    % constructor called with device name or address
                    obj.BluetoothDevice = bluetooth(connectionInfo);
                end
                % Get the device properties from Bluetooth layer
                obj.Name = obj.BluetoothDevice.Name;
                obj.Address = obj.BluetoothDevice.Address;
            catch e
                % Update Bluetooth error context to BITalino specific error
                % message
                errObj = updateErrorContext(obj,e);
                throwAsCaller(errObj);
            end

            % Store the last device information for connecting next time
            % without any argument
            if isvalid(obj) && ~isempty(obj.Name) && ~isempty(obj.Address)
                matlabshared.bitalinolib.internal.LastConnectionInfo.set(obj.Name, obj.Address);
            end
        end
    end
    methods(Access=public)

        %% Read data acquired from the BITalino
        function biosignalData = read(obj, options)
            % Read the data from the Bluetooth transport layer

            import matlabshared.bitalinolib.internal.BitalinoConstants

            % Flush any garbage data present in buffer
            flush(obj.BluetoothDevice);

            % Set reading mode to simulated if the user requested to use
            % simulated mode
            if isfield(options, "UseSimulated") && options.UseSimulated
                obj.ReadMode = BitalinoConstants.SimulatedMode;
            end

            try
                if ~isfield(options, "Duration") && ~isfield(options, "NumSamples")
                    % If there was no number of samples or duration provided for
                    % reading, read one sample
                    obj.NumBytesToRead = BitalinoConstants.NumBytesPerSample;
                    % Switch from Idle mode to live or simulated mode for
                    % reading
                    write(obj, obj.ReadMode);
                    biosignalData = read(obj.BluetoothDevice, obj.NumBytesToRead,'uint8');
                    write(obj, BitalinoConstants.IdleMode);
                else
                    if isfield(options, "Duration")
                        % Duration for reading provided
                        obj.NumBytesToRead = options.Duration*obj.SampleRate*8;
                    else
                        % Number of samples for reading provided
                        obj.NumBytesToRead = options.NumSamples*BitalinoConstants.NumBytesPerSample;
                    end
                    write(obj,obj.ReadMode);
                    % Switch from Idle mode to live or simulated mode for
                    % reading, read bytes in cycles or at once
                    if obj.NumBytesToRead >= BitalinoConstants.BytesPerSingleRead
                        biosignalData = zeros(1,obj.NumBytesToRead,'uint8');
                        % Initialize the current position in the data array
                        currentPosition = 1;

                        % Calculate the number of read cycles
                        numReadCycles = floor(obj.NumBytesToRead/BitalinoConstants.BytesPerSingleRead);

                        % Calculate the remainder bytes after the end of
                        % read cycles
                        remainderBytes = mod(obj.NumBytesToRead,BitalinoConstants.BytesPerSingleRead);

                        % Acquire data executing all the read cycles
                        for itr = 1:numReadCycles
                            biosignalData(currentPosition:(currentPosition+BitalinoConstants.BytesPerSingleRead-1))...
                                = read(obj.BluetoothDevice,BitalinoConstants.BytesPerSingleRead,'uint8');
                            currentPosition = currentPosition+BitalinoConstants.BytesPerSingleRead;
                        end

                        % Read the remainder bytes if any
                        if remainderBytes > 0
                            biosignalData(currentPosition:currentPosition+remainderBytes-1)...
                                = read(obj.BluetoothDevice,remainderBytes,'uint8');
                        end
                    else
                        % If data to read is less than bytes to read per
                        % cycle, read at once
                        biosignalData = read(obj.BluetoothDevice,obj.NumBytesToRead,'uint8');
                    end
                    % Configure BITalino to stop sending data
                    write(obj,BitalinoConstants.IdleMode);
                end

                flush(obj.BluetoothDevice);
                if isempty(biosignalData) || length(biosignalData)~= obj.NumBytesToRead
                    error(BitalinoConstants.BitalinoMessages.failedRead);
                end
                % Reshape the data into 8 byte packets for further decoding
                biosignalData = reshape(biosignalData,[BitalinoConstants.NumBytesPerSample,...
                    obj.NumBytesToRead/BitalinoConstants.NumBytesPerSample])';
            catch e
                throwAsCaller(e);
            end
        end

        %% Write data to the BITalino
        function write(obj, data)
            % Process any pending callback in MATLAB queue before write
            drawnow limitrate
            % Internal function used to send data to the bitalino
            write(obj.BluetoothDevice, uint8(data));
        end
    end

    methods(Access = protected)
        function firmwareVersion = readFirmwareVersion(obj)
            % Get firmware version of BITalino
            firmwareVersion = [];
            if ~(obj.BluetoothDevice.NumBytesAvailable == 0)
                % Read firmware version string avoiding the newline at the
                % end if there is data available to read
                firmwareData =  read(obj.BluetoothDevice, obj.BluetoothDevice.NumBytesAvailable-1);
                firmwareVersion = string(char(firmwareData));
            end
        end
    end

    methods(Access = private)
        function updatedErrorObj = updateErrorContext(~, errorObj)
            % Function to update error context from Bluetooth Classic
            % to BITalino

            import matlabshared.bitalinolib.internal.BitalinoConstants

            updatedErrorObj = errorObj;
            tags = strsplit(errorObj.identifier,":");
            errorID = tags{end};
            try
                % Check if the same ID is present in the BITalino error
                % catalog
                bitalinoContextErrorId = sprintf("%s:%s",...
                    BitalinoConstants.BitalinoErrorIdContext, errorID);
                bitalinoContextErrorMsg = BitalinoConstants.BitalinoMessages.(errorID);
                updatedErrorObj = MException(bitalinoContextErrorId,bitalinoContextErrorMsg);
            catch
                % Return the same error object without modification if the
                % BITalino error catalog does not have the ID
            end
        end
    end
end

% LocalWords:  bitalino