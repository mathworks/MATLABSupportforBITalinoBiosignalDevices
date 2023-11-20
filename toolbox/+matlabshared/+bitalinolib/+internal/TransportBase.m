classdef TransportBase < handle
    %TRANSPORTBASE - Base transport class for communication with BITalino

    % Copyright 2023 The MathWorks, Inc.

    properties (Access=public)
        %Name - Peripheral name
        Name
        %Address - Peripheral address
        Address
        % Current sample rate set on BITalino
        SampleRate
        %Firmware version of BITalino
        FirmwareVersion
    end

    properties(Access=protected)
        % Digital pin command is 0b1011x4x311, where x4 & x3 are the
        % values of pin O1 and O2 respectively
        DigitalOutputValue = 0b10110011
        % Value to set for O1 & O2 pins to turn on/off
        O1Value
        O2Value

        % Default read mode is live mode
        % 0b11111101 - Acquisition from 6 analog channels in live mode
        ReadMode = 253;
    end

    methods(Abstract)
        % Methods defined in the actual transport class

        % Read from BITalino
        biosignal = read(obj, readOptions);
        % Write to BITalino
        write(obj, data);
    end

    methods(Abstract, Access = protected)
        % Get BITalino firmware version, defined in the transport layer
        % class
        firmwareVersion = readFirmwareVersion(obj)
    end

    %% Helper methods
    methods
        function decodedData = decodeFrames(~, data)
            % Decode the data Frames and return an array of data

            import matlabshared.bitalinolib.internal.BitalinoConstants

            % NOTE: The following code does bitwise operations to decode the
            % data in each packet. Refer to the data packet structure below
            % for information on ordering of data within a packet while
            % acquiring from all 6 analog channels

            %             b8     b7      b6      b5      b4      b3      b2      b1
            % Byte 1     A5(2)  A5(1)   A6(6)   A6(5)   A6(4)   A6(3)   A6(2)   A6(1)
            % Byte 2     A4(4)  A4(3)   A4(2)   A4(1)   A5(6)   A5(5)   A5(4)   A5(3)
            % Byte 3     A3(2)  A3(1)   A4(10)  A4(9)   A4(8)   A4(7)   A4(6)   A4(5)
            % Byte 4     A3(10) A3(9)   A3(8)   A3(7)   A3(6)   A3(5)   A3(4)   A3(3)
            % Byte 5     A2(8)  A2(7)   A2(6)   A2(5)   A2(4)   A2(3)   A2(2)   A2(1)
            % Byte 6     A1(6)  A1(5)   A1(4)   A1(3)   A1(2)   A1(1)   A2(10)  A2(9)
            % Byte 7      I1     I2      O1      O2     A1(10)  A1(9)   A1(8)   A1(7)
            % Byte 8     Seq4   Seq3    Seq2    Seq1    CRC4    CRC3    CRC2    CRC1

            % Calculate the number of analog channels in one data packet
            numAnalogChannels = length(data(1, :)) - 2;

            % Pre-allocate decodedData based on number of analog channels
            decodedData = zeros(size(data,1),...
                (BitalinoConstants.NumConstantFields + numAnalogChannels));

            for idx = 1:size(data, 1)

                % Extract one data packet to decode
                biosignal = data(idx, :);

                % Decode the Sequential Number (packetNumber). This ranges
                % from 0-15
                sequence = bitshift(bitand(biosignal(end), 0xf0), -4);

                % Decode digitalInputs
                % Extract 8th bit of 7th byte with 128 ('10000000')
                I1 = bitshift(bitand(biosignal(end-1), 128), -7);
                % Extract 7th bit of 7th byte with 64 ('01000000')
                I2 = bitshift(bitand(biosignal(end-1), 64), -6);

                % Decode digitalOutputs
                % Extract 6th bit of 7th byte with 32 ('00100000')
                O1 = bitshift(bitand(biosignal(end-1), 32), -5);
                % Extract 5th bit of 7th byte with 16 ('00010000')
                O2 = bitshift(bitand(biosignal(end-1), 16), -4);

                % Array to hold the decoded analog channel data
                channels = zeros(1, numAnalogChannels);

                % Lower 4 bits of end-1 row followed by upper 6 bits of the
                % end-2 row constitutes the 10 bits of channel 1
                channels(1) = bitand(bitshift(uint16(biosignal(end-2)) +...
                    bitshift(uint16(biosignal(end-1)), BitalinoConstants.ShiftToUpperByte),...
                    BitalinoConstants.ShiftForChannel1), BitalinoConstants.Extract10Bits);

                % Lower 2 bits of end-2 row followed by 8 bits of end-3 row
                % constitutes the 10 bits of channel 2
                if numAnalogChannels > 1
                    channels(2) = bitand(uint16(biosignal(end-3)) +...
                        bitshift(uint16(biosignal(end-2)), BitalinoConstants.ShiftToUpperByte),...
                        BitalinoConstants.Extract10Bits);
                end

                % 8 bits of end-4 row followed by upper 2 bits of the end-5
                % row constitutes the 10 bits of channel 3
                if numAnalogChannels > 2
                    channels(3) = bitand(bitshift(uint16(biosignal(end-5)) +...
                        bitshift(uint16(biosignal(end-4)), BitalinoConstants.ShiftToUpperByte),...
                        BitalinoConstants.ShiftForChannel3), BitalinoConstants.Extract10Bits);
                end

                % Lower 6 bits of end-5 row followed by upper 4 bits of the
                % end-6 row constitutes the 10 bits of channel 4
                if numAnalogChannels > 3
                    channels(4) = bitand(bitshift(uint16(biosignal(end-6)) +...
                        bitshift(uint16(biosignal(end-5)), BitalinoConstants.ShiftToUpperByte),...
                        BitalinoConstants.ShiftForChannel4), BitalinoConstants.Extract10Bits);
                end

                % Lower 4 bits of end-6 row followed by upper 2 bits of the
                % end-7 row constitutes the 6 bits of channel 5
                if numAnalogChannels > 4
                    channels(5) = bitand(bitshift(uint16(biosignal(end-7)) +...
                        bitshift(uint16(biosignal(end-6)), BitalinoConstants.ShiftToUpperByte),...
                        BitalinoConstants.ShiftForChannel5), BitalinoConstants.Extract6Bits);
                end

                % 6 bits of end-7 row constitues the 6 bits of channel 6
                if numAnalogChannels > 5
                    channels(6) = bitand(uint16(biosignal(end-7)), BitalinoConstants.Extract6Bits);
                end

                % Assign the fixed fields
                decodedData(idx, 1:5) = [sequence, I1, I2, O1, O2];
                % Assign the analog channel data
                decodedData(idx, 6:11) = channels(1:numAnalogChannels);
            end
        end


        function writeDigitalPins(obj, pins, values)
            % Write to one or both of the BITalino's digital output pins

            import matlabshared.bitalinolib.internal.BitalinoConstants

            o1flag = false;
            o2flag = false;
            for i = 1:numel(pins)
                switch lower(pins{i})
                    case 'o1'
                        obj.O1Value = values(i);
                        o1flag = true;
                    case 'o2'
                        obj.O2Value = values(i);
                        o2flag = true;
                end
            end

            if o1flag && o2flag
                % If both pins need to be turn on, set the bit
                % corresponding to the position of O1 & O2
                obj.DigitalOutputValue = bitset(obj.DigitalOutputValue,BitalinoConstants.O1Pos,...
                    obj.O1Value);
                obj.DigitalOutputValue = bitset(obj.DigitalOutputValue,BitalinoConstants.O2Pos,...
                    obj.O2Value);
            elseif o1flag && ~o2flag
                % Only turn on O1
                obj.DigitalOutputValue = bitset(obj.DigitalOutputValue,BitalinoConstants.O1Pos,...
                    obj.O1Value);
            else
                % Only turn on O2
                obj.DigitalOutputValue = bitset(obj.DigitalOutputValue,BitalinoConstants.O2Pos,...
                    obj.O2Value);
            end

            % Write the above formulated configuration string to turn
            % on/off O1 and O2 pins
            write(obj, obj.DigitalOutputValue);
        end
    end

    methods
        %% Set BITalino SampleRate
        function set.SampleRate(obj, value)
            % Get configuration value to set desired sample rate
            valueToWrite = getSampleRateValue(obj, value);
            % Write configuration in BITalino
            write(obj,valueToWrite);
            % Update SampleRate
            obj.SampleRate = value;
        end

        function firmwareVersion = get.FirmwareVersion(obj)
            import matlabshared.bitalinolib.internal.BitalinoConstants

            % Write device configuration to BITalino to get firmware
            % version
            write(obj, BitalinoConstants.FirmwareConfiguration);
            % Sporadically we don't get any data if we try to read right
            % after the write, this pause helps to get the firmware data
            % reliably
            pause(BitalinoConstants.DeviceTimeout);
            % Get firmware version returned by BITalino
            firmwareVersion = readFirmwareVersion(obj);
        end
    end

    methods (Access = private)
        function valueToWrite = getSampleRateValue(~, value)
            import matlabshared.bitalinolib.internal.BitalinoConstants
            switch value
                % SampleRate configuration strings
                % 0b11000011 - 1000Hz sample rate
                % 0b10000011 - 100Hz sample rate
                % 0b01000011 - 10Hz sample rate
                % 0b00000011 - 1Hz sample rate
                case 1000
                    valueToWrite = BitalinoConstants.SampleRate1000;
                case 100
                    valueToWrite = BitalinoConstants.SampleRate100;
                case 10
                    valueToWrite = BitalinoConstants.SampleRate10;
                case 1
                    valueToWrite = BitalinoConstants.SampleRate1;
            end
        end
    end
end
