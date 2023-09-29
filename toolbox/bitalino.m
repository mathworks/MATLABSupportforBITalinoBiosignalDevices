classdef (Sealed) bitalino < matlab.mixin.SetGet & matlab.mixin.CustomDisplay
    %BITALINO Creates a connection to a BITalino biosignal device.
    %
    %  b = BITALINO creates a connection to a previously connected BITalino
    %  biosignal device.
    %
    %   b = BITALINO(name) creates a connection to a BITalino biosignal device
    %   that has the specified name.
    %
    %   b = BITALINO(address) creates a connection to a BITalino biosignal device
    %   that has the specified address.
    %
    %   Identify the device name or address using bitalinolist.
    %
    %   BITALINO methods:
    %
    %   read - Reads biosignal data from A1-A6 analog channels and status
    %   of I1, I2, O1 & O2 digital and returns the data in a timetable
    %   format with relative time along with packet sequence number.
    %
    %   writeDigitalPins - Sets/unsets digital pins O1 and O2
    %
    %   BITALINO properties:
    %
    %   Name                       - Specifies the device name
    %   Address                    - Specifies the device address
    %   FirmWareVersion            - Specifies the current firmware version
    %   AvailableAnalogPins        - Specifies the analog pins available on
    %   the device
    %   AvailableDigitalInputPins  - Specifies the digital input pins
    %   available on the device
    %   AvailableDigitalOutputPins - Specifies the digital output pins
    %   available on the device
    %   SampleRate                 - Specifies the current sample rate set
    %   on the device
    %
    %   Examples:
    %       % Connect to a BITalino peripheral device with name
    %       BITalino-12-34
    %       b = bitalino("BITalino-12-34")
    %
    %       % Connect to a BITalino peripheral device with address
    %       % 0570B282CF53 on Windows
    %       b = bitalino("0570B282CF53")
    %
    %       % Connect to a Bluetooth Low Energy peripheral with address
    %       % 5E4F4F17-7A25-4AB3-AA67-B68355FB5D78 on Mac
    %       b = bitalino("5E4F4F17-7A25-4AB3-AA67-B68355FB5D78")
    %
    %       % Connect to BITalino and set the SampleRate to 100
    %       b = bitalino("BITalino-12-34","SampleRate",100)
    %
    %   See also bitalinolist, read, writeDigitalPins

    % Copyright 2023 The MathWorks, Inc.

    properties(GetAccess = public, SetAccess = private)
        %Name - BITalino name
        Name
        %Address - BITalino address
        Address
        %FirmwareVersion - Current device firmware version
        FirmwareVersion
    end

    properties(Constant)
        %AvailableAnalogPins
        AvailableAnalogPins = matlabshared.bitalinolib.internal.BitalinoConstants.AvailableAnalogPins
        %AvailableDigitalInputPins
        AvailableDigitalInputPins = matlabshared.bitalinolib.internal.BitalinoConstants.AvailableDigitalInputPins
        %AvailableDigitalOutputPins
        AvailableDigitalOutputPins = matlabshared.bitalinolib.internal.BitalinoConstants.AvailableDigitalOutputPins
    end

    properties
        %SampleRate - Supported sample rates are 1, 10, 100 and 1000
        SampleRate
    end

    properties(Access = private)
        % Transport layer that communicates with BITalino device
        Transport
    end

    methods
        function obj = bitalino(connectionInfo, options)
            %BITALINO Construct a bitalino object given optional input
            % arguments.
            % If no input arguments are provided, it attempts to connect to
            % a previously connected BITalino device.
            arguments
                % Name or Address of the BITalino
                connectionInfo string {mustBeNonzeroLengthText} = strings().empty
                options.SampleRate (1,1) double...
                    {matlabshared.bitalinolib.internal.Utility.validateSampleRate(options.SampleRate)} = 1000
            end

            try
                matlabshared.bitalinolib.internal.Utility.validatePlatform();

                % Get the transport layer object and update the object
                % property details
                obj.Transport = matlabshared.bitalinolib.internal.TransportFactory.getTransport(connectionInfo);
                obj.Name = obj.Transport.Name;
                obj.Address = obj.Transport.Address;
                obj.SampleRate = options.SampleRate;
                obj.FirmwareVersion = obj.Transport.FirmwareVersion;

            catch e
                throwAsCaller(e);
            end


        end
        function biosignal = read(obj, options)
            % Reads biosignal data from A1 to A6 analog channels, status
            % of I1, I2, O1 & O2 digital channels and returns it in a
            % timetable format with relative time along with packet
            % sequence numbers.
            %%   Examples:
            %       % Read 1 sample from BITalino device, live from sensors
            %       data = read(bitalinoObj)
            %
            %       % Read 10 samples from BITalino device, live from sensors
            %       data = read(bitalinoObj,"NumSamples",10)
            %
            %       % Read for 10 secs from BITalino, acquiring
            %       pre-recorded data from BITalino firmware
            %       data = read(bitalinoObj,"Duration",10,"UseSimulated",true)
            arguments
                obj
                options.Duration (1,1) double {mustBePositive,...
                    mustBeInteger}
                options.NumSamples (1,1) double {mustBePositive,...
                    mustBeInteger}
                options.UseSimulated {mustBeUnderlyingType(...
                    options.UseSimulated,"logical")}
            end
            import matlabshared.bitalinolib.internal.BitalinoConstants

            if isfield(options, "Duration") && isfield(options,...
                    "NumSamples")

                errorID = sprintf("%s:invalidReadArguments",...
                    BitalinoConstants.BitalinoErrorIdContext);
                ME = MException(errorID,...
                    BitalinoConstants.BitalinoMessages.invalidReadArguments);
                throwAsCaller(ME);
            end
            acquiredSignal = read(obj.Transport, options);
            % Decode biosignal acquired from BITalino
            decodedBiosignal = decodeFrames(obj.Transport, acquiredSignal);
            % Convert the decoded data to a time table format with relative
            % time
            biosignal = array2timetable(decodedBiosignal,...
                'SampleRate',obj.SampleRate);
            biosignal.Properties.VariableNames = BitalinoConstants.BiosignalVariableNames;
        end

        function writeDigitalPins(obj, pins, values)
            % Writes the specified values to the specified pins.
            % Example: writeDigitalPins(b,["O1", "O2"],[true, false])
            % turns on the O1 pin and turns off the O2 digital output pin.
            %
            %%   Examples:
            %       % Turn off O1(LED) and turn on O2(Buzzer) digital
            %       output pins
            %       writeDigitalPins(bitalinoObj,["O1","O2"],[false,true])
            %
            %       % Turn on O2(Buzzer) digital output pin
            %       writeDigitalPins(bitalinoObj,"O2",true)
            arguments
                obj
                pins (1,:) {mustBeText}
                % Pin value must be true/false or 0/1
                values (1,:) {mustBeNumericOrLogical, mustBeMember(values, [0,1])}
            end
            import matlabshared.bitalinolib.internal.BitalinoConstants

            % A case insensitive validation of digital pin names
            mustBeMember(upper(pins), ["O1", "O2"]);

            if (numel(unique(pins)) ~= numel(pins))
                % Error out if input contains a pin value multiple times
                errorID = sprintf("%s:duplicatePinValue",...
                    BitalinoConstants.BitalinoErrorIdContext);
                ME = MException(errorID, BitalinoConstants.BitalinoMessages.duplicatePinValue);
                throwAsCaller(ME);
            end

            if (numel(pins) ~= numel(values))
                % Error out if input does not have value for all specified
                % pins
                errorID = sprintf("%s:mismatchedPinValue",...
                    BitalinoConstants.BitalinoErrorIdContext);
                ME = MException(errorID, BitalinoConstants.BitalinoMessages.mismatchedPinValue);
                throwAsCaller(ME);
            end

            % Write the pin values to BITalino through transport layer
            writeDigitalPins(obj.Transport,  pins, values);
        end

        function set.SampleRate(obj, sampleRate)
            % Set the sampling rate, in Hz, of the BITalino. Valid sample
            % rates are 1Hz, 10Hz, 100Hz and 1000Hz. Example:
            %
            % bitalinoObj.SampleRate = 100
            arguments
                obj
                sampleRate (1,1) double...
                     {matlabshared.bitalinolib.internal.Utility.validateSampleRate(sampleRate)}
            end
            % Update sample rate in transport layer
            updateSampleRate(obj, sampleRate);
            obj.SampleRate = sampleRate;
        end
    end
    methods(Access=private)
        function updateSampleRate(obj, sampleRate)
            % Update sample rate in BITalino through transport layer
            obj.Transport.SampleRate = sampleRate;
        end
    end
end

