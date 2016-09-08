classdef Perceptron < MappingUnit
    methods
        function y = process(obj, x)
            y = obj.act.transform(obj.linproc.transform(x));
        end
        
        function d = errprop(obj, d, isEvolving)
            if exist('isEvolving', 'var')
                d = obj.linproc.errprop(obj.act.errprop(d), isEvolving);
            else
                d = obj.linproc.errprop(obj.act.errprop(d), true);
            end
        end
        
        function update(obj, stepsize)
            if exist('stepsize', 'var')
                obj.linproc.update(stepsize);
            else
                obj.linproc.update();
            end
        end
    end
    
    methods
        function unit = inverseUnit(obj) % TEMPORARY SOLUTION
            unit = Perceptron( ...
                double(obj.outputSizeDescription), ...
                double(obj.inputSizeDescription), ...
                'actType', obj.act.actType);
        end
        
        function kernel = kernelDump(obj)
            kernel = obj.linproc.kernelDump();
        end
    end
    
    % ======================= SIZE DESCRIPTION =======================
    properties (Dependent)
        inputSizeRequirement
    end
    methods
        function value = get.inputSizeRequirement(obj)
            value = obj.linproc.inputSizeDescription;
        end
        
        function descriptionOut = sizeIn2Out(obj, descriptionIn)
            descriptionOut = obj.act.sizeIn2Out( ...
                obj.linproc.sizeIn2Out(descriptionIn));
        end
    end
    
    % ======================= CONSTRUCTOR =======================
    methods
        function obj = Perceptron(inputSize, outputSize, varargin)
            conf = Config(varargin);
            obj.linproc = LinearTransform(inputSize, outputSize);
            if not(conf.pop('noactivation', false))
                obj.act = Activation(conf.get('actType', 'ReLU'));
            end
            conf.apply(obj);
        end
    end
    
    % ======================= DATA STRUCTURE =======================
    properties
        linproc, act = NullUnit()
    end
    
    properties (Dependent)
        actType
    end
    methods
        function value = get.actType(obj)
            value = obj.act.actType;
        end
        function set.actType(obj, value)
            obj.act.actType = value;
        end
    end
    
    % ======================= DEVELOPER TOOL =======================
    methods (Static)
        function debug()
            sizein  = 64;
            sizeout = 16;
            batchsize = 16;
            % Setting : Sigmoid
            refer = Perceptron(sizein, sizeout, 'actType', 'sigmoid');
            refer.linproc.bias = randn(size(refer.linproc.bias));
            model = Perceptron(sizein, sizeout, 'actType', 'sigmoid');
            model.likelihood = Likelihood('logistic');
            % create validate set
            data = randn([sizein, 1e2]);
            validset = DataPackage(data, 'label', refer.transform(data));
            % start to learn the linear transformation
            fprintf('Initial objective value : %.2f\n', ...
                    model.likelihood.evaluate(model.forward(validset)));
            for i = 1 : UMPrest.parameter.get('iteration')
                data  = randn([sizein, batchsize]);
                label = refer.transform(data);
                dpkg  = DataPackage(data, 'label', label);
                model.learn(dpkg);
                fprintf('Objective Value after [%04d] turns: %.2f\n', i, ...
                    model.likelihood.evaluate(model.forward(validset)));
            end
            % show result
            werr = refer.linproc.weight - model.linproc.weight;
            berr = refer.linproc.bias - model.linproc.bias;
            fprintf('Estimate Weight Error > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(werr(:)), var(werr(:)), max(abs(werr(:))));
            fprintf('Estimate Bias Error   > MEAN:%-8.2e\tVAR:%-8.2e\tMAX:%-8.2e\n', ...
                mean(berr(:)), var(berr(:)), max(abs(berr(:))));
        end
    end
end
