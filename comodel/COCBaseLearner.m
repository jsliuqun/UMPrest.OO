% CLASS : COModel
%
% Class derived from base class MotionLearner that implementing Cadieu &
% Olshausen's model in their 2012 paper. This program just implemented the
% first layer of this two layers model. The first layer is a generative
% model bases on complex bases.
%
% MooGu Z. <hzhu@case.edn>
%
% Oct 20, 2015 - Initial commit

classdef COCBaseLearner < ComplexICA
    % ================= GENERATIVEMODEL IMPLEMENTATION =================
    methods
        function update(obj, delta)
            obj.base = obj.base + delta;
            % utilize GS orthogonalization
            obj.base = complex(real(obj.base), imag(obj.base) - real(obj.base) ...
                * diag(sum(real(obj.base) .* imag(obj.base)) ./ sum(real(obj.base).^2)));
            % flip real and imaginary part
            obj.base = complex(imag(obj.base), real(obj.base));
            % renormalize length of bases (separate real and image part)
            obj.base = complex( ...
                bsxfun(@rdivide, real(obj.base), sqrt(sum(real(obj.base).^2))), ...
                bsxfun(@rdivide, imag(obj.base), sqrt(sum(imag(obj.base).^2))));
        end

        function objval = evaluate(obj, sample, respond)
            if not(isfield(sample, 'error'))
                sample.error = obj.calcError(sample, respond);
            end

            objval.noise  = obj.noise(sample.error);
            objval.sparse = obj.sparse(respond.data.amplitude);
            objval.stable = obj.stable(respond.data.amplitude);
            objval.value  = objval.noise + objval.sparse + objval.stable;
        end

        function mgrad = modelGradient(obj, sample, respond)
            if not(isfield(sample, 'error'))
                sample.error = obj.calcError(sample, respond);
            end
            % [dnoise/derror] : gradient of err under function noise
            errGrad = obj.dnoise(sample.error);
            % [dnoise/dA = - (dnoise/derror) * Z'] :  however, due to
            % performance concern, use a method involve only real number in
            % the calculation.
            mgrad = -complex(errGrad * (respond.data.amplitude .* cos(respond.data.phase))', ...
                errGrad * (respond.data.amplitude .* sin(respond.data.phase))');
        end

        function rgrad = respondGradient(obj, sample, respond)
            if not(isfield(sample, 'error'))
                sample.error = obj.calcError(sample, respond);
            end
            % (dnoise/derror) : gradient of err under function noise
            errGrad = obj.dnoise(sample.error);
            % gradient of respond.data.amplitude composed by three parts :
            % noise, sparse, and stable.
            rgrad.amplitude = obj.dsparse(respond.data.amplitude) ...
                + obj.dstable(respond.data.amplitude) ...
                - cos(respond.data.phase) .* (real(obj.base)' * errGrad) ...
                - sin(respond.data.phase) .* (imag(obj.base)' * errGrad);
            % gradient of respond.data.phase only related to noise
            rgrad.phase = sin(respond.data.phase) .* (real(obj.base)' * errGrad) ...
                - cos(respond.data.phase) .* (imag(obj.base)' * errGrad);
            if not(obj.naturalGradient)
                rgrad.phase = respond.data.amplitude .* rgrad.phase;
            end
        end
    end

    % ================= PROBABILITY DESCRIPTION =================
    methods (Access = private)
        function prob = noise(obj, error)
            % this portion is described by Gaussian Distribution, however,
            % with sigma = 1. Due to the performance concern, use the
            % simplest calculation method here. Noted the error is weighted
            % with noise factor calculated from whitening module.
            prob = obj.nlGauss(bsxfun(@times, sqrt(obj.noiseFactor), error), 1) / size(error, 2);
        end
        function grad = dnoise(obj, error)
            grad = bsxfun(@times, obj.noiseFactor, error) / size(error, 2);
        end

        function prob = sparse(obj, data)
            prob = obj.betaSparse * obj.nlCauchy(data, obj.sigmaSparse) / size(data, 2);
        end
        function grad = dsparse(obj, data)
            grad = obj.betaSparse * obj.dNLCauchy(data, obj.sigmaSparse) / size(data, 2);
        end

        function prob = stable(obj, data)
            prob = obj.nlGauss(diff(data, 1, 2), obj.sigmaStable) / size(data, 2);
        end
        function grad = dstable(obj, data)
            grad = - obj.dNLGauss( ...
                diff(padarray(data, [0,1], 'replicate', 'both'), 2, 2), ...
                obj.sigmaStable) / size(data, 2);
        end
    end
    % ================= SUPPORT FUNCTION =================
    methods (Access = private)
        function error = calcError(obj, sample, respond)
            error = sample.data - obj.generate(respond).data;
        end
    end

    % ================= DATA STRUCTURE =================
    properties
        % ------- INFER -------
        inferOption = struct( ...
            'Method', 'bb', ...
            'Display', 'off', ...
            'MaxIter', 17, ...
            'MaxFunEvals', 23);
        % ------- ADAPT -------
        adaptStep      = 1e-4;
        etaTarget      = 0.05;
        stepUpFactor   = 1.02;
        stepDownFactor = 0.95;
        % ------- RESPONDGRADIENT -------
        naturalGradient = true;
        % ------- PROBABILITY DESCRIPTION -------
        betaSparse  = 10;
        sigmaSparse = 0.4;
        sigmaStable = sqrt(2);
    end
    properties (Dependent, Access = private)
        noiseFactor
    end
    methods
        function value = get.noiseFactor(obj)
            value = obj.preproc.stack{2}.noiseFactor;
        end
    end

    % ================= LANGUAGE UTILITY =================
    methods
        function obj = COCBaseLearner(nbase, varargin)
            obj.nbase = nbase;
            obj.setupByArg(varargin{:});
            obj.preproc.setupByArg(varargin{:});
            obj.preproc.push(Recenter());
            obj.preproc.push(Whitening(varargin{:}));
            obj.consistencyCheck();
        end

        function consistencyCheck(obj)
            obj.consistencyCheck@ComplexICA();
        end
    end
end
