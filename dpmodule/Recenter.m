classdef Recenter < DPModule & LibUtility
    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function sample = proc(obj, sample)
            sample.data = bsxfun(@minus, sample.data, obj.biasVector);
        end

        function sample = invp(obj, sample)
            sample.data = bsxfun(@plus, sample.data, obj.biasVector);
        end

        function setup(obj, sample)
            assert(numel(size(sample.data)) == 2);
            obj.biasVector = mean(sample.data, 2);
        end

        function tof = ready(obj)
            tof = ~isempty(obj.biasVector);
        end

        function n = dimin(obj)
            assert(obj.ready());
            n = numel(obj.biasVector);
        end

        function n = dimout(obj)
            n = obj.dimin();
        end
    end

    % ================= DATA STRUCTURE =================
    properties (Hidden)
        biasVector
    end

    % ================= DPMODULE IMPLEMENTATION =================
    methods
        function obj = Recenter(varargin)
            obj.setupByArg(varargin{:});
        end
    end
end
