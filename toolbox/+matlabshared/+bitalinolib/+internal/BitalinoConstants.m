classdef BitalinoConstants < handle
    %BITALINOCONSTANTS - Class that stores constant values used throughout
    % MATLAB Support for BITalino Devices

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties(Constant, GetAccess = public)
        % BITalino sends 8 bytes in a data packet consisting all 6 Analog
        % channels
        NumBytesPerSample = 8

        % Supported sample rates by BITalino
        % 0b11000011 - 1000Hz sample rate
        SampleRate1000 = 195
        % 0b10000011 - 100Hz sample rate
        SampleRate100 = 131
        % 0b01000011 - 10Hz sample rate
        SampleRate10 = 67
        % 0b00000011 - 1Hz sample rate
        SampleRate1 = 3

        % Supported modes
        % 0 = 0b00000000 - idle mode
        IdleMode = 0;
        % 253 = 0b11111101 - live 6 analog channels
        LiveMode = 253;
        % 254 = 0b11110110 - simulated 6 analog channels
        SimulatedMode = 254;

        % Firmware Version string - 0b00000111
        FirmwareConfiguration = 7

        % The BITalino firmware needs time to process commands.
        % This prevents commands from being dropped by the firmware.
        DeviceTimeout = 0.2;

        % Position of bit for O1 and O2 digital pins in the configuration
        % string
        O1Pos = 3
        O2Pos = 4

        % Error ID for error message texts
        BitalinoErrorIdContext = "MATLAB:bitalino";

        % Name of the variables in the acquired biosignal data
        BiosignalVariableNames = ...
            ["Sequence","I1","I2","O1","O2","A1","A2","A3","A4","A5","A6"]

        % Sample rates supported by BITalino
        SupportedSampleRates = [1 10 100 1000]

        % Analog and digital pins available in BITalino
        AvailableAnalogPins = ["A1", "A2", "A3", "A4", "A5", "A6"]
        AvailableDigitalInputPins = ["I1", "I2"]
        AvailableDigitalOutputPins = ["O1", "O2"]

        % BITalino error message texts
        BitalinoMessages = matlabshared.bitalinolib.internal.Utility.getAppMessageTexts();

        % Sequence, I1, I2, O1 and O2 are constant fields in decoded data
        NumConstantFields = 5

        % Constant to extract upper 4 bits of the last byte of the data
        % packet for sequence number
        ExtractSequenceBits = 240;

        % Constant to extract lower 4 bits of the last byte of the data
        % packet for CRC
        ExtractCRCBits = 15;

        % Constants to extract analog channel data from data packet
        Extract10Bits = 1023;
        Extract6Bits = 63;

        % Shifting factor for shifting least significant 8 bits to the
        % upper byte
        ShiftToUpperByte = 8;

        % Shifiting factor for first analog channel of the data packet
        ShiftForChannel1 = -2;
        % Shifiting factor for third analog channel of the data packet
        ShiftForChannel3 = -6;
        % Shifiting factor for fourth analog channel of the data packet
        ShiftForChannel4 = -4;
        % Shifiting factor for fifth analog channel of the data packet
        ShiftForChannel5 = -6;

        % Number of Bytes to read per read cycle
        BytesPerSingleRead = 100000;
    end

end

% LocalWords:  bitalino biosignal