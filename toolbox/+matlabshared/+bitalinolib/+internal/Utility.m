classdef Utility < handle
    % UTILITY - Utility class for bitalino

    % Copyright 2023 The MathWorks, Inc.

    methods(Static)
        function bitalinoMessages = getAppMessageTexts()
            persistent errorMessage;

            if isempty(errorMessage)
                % Function to get error message texts from the XML file
                [pathstr, ~, ~] = fileparts(mfilename('fullpath'));
                errorMessage = readstruct(fullfile(pathstr, 'BitalinoMessageTexts.xml'));
            end
            bitalinoMessages = errorMessage;
        end

        function devices = bitalinoTabCompletionHelper(option)
            % Function to help with device name or address in tab
            % completion
            list = bitalinolist;
            switch(lower(string(option)))
                case "name"
                    devices = list.Name;
                case "address"
                    devices = list.Address;
            end
        end

        function validatePlatform()
            % Check if platform is supported.

            import matlabshared.bitalinolib.internal.BitalinoConstants
            % Error out if the platform is not Windows or macOS
            if ~(ispc || ismac)
                errorID = sprintf("%s:unsupportedPlatform",...
                    BitalinoConstants.BitalinoErrorIdContext);
                ME = MException(errorID, BitalinoConstants.BitalinoMessages.unsupportedPlatform);
                throwAsCaller(ME);
            end
        end

        function validateSampleRate(sampleRate)
            % Check if sample rate is supported.

            % Error out if the sample rate is not among the supported
            % values defined
            mustBeMember(sampleRate,...
                matlabshared.bitalinolib.internal.BitalinoConstants.SupportedSampleRates)
        end
    end
end
