classdef RecurrentUnit < Unit & Evolvable
    methods
        function varargout = forward(obj, varargin)
            obj.pkginfo = RecurrentAP.initPackageInfo();
            % clear hidden state
            for i = 1 : numel(obj.S)
                obj.S{i}.clear();
            end
            % extract frames from packages
            if isempty(varargin)
                for i = 1 : numel(obj.I)
                    obj.I{i}.extract();
                end
            else
                for i = 1 : numel(obj.I)
                    obj.I{i}.extract(varargin{i});
                end
            end
            % process frames one by one
            for t = 1 : obj.pkginfo.nframe
                % send frame to kernel
                for i = 1 : numel(obj.I)
                    obj.I{i}.sendFrame();
                end
                % update state in kernel
                for i = 1 : numel(obj.S)
                    obj.S{i}.forward();
                end
                % process data by kernel
                obj.kernel.forward();
            end
            % compress frames into package
            varargout = cellfun(@compress, obj.O, 'UniformOutput', false);
            if nargout == 0
                for i = 1 : numel(obj.O)
                    obj.O{i}.send(varargout{i});
                end
            end
        end
        
        function varargout = backward(obj, varargin)
            obj.pkginfo = RecurrentAP.initPackageInfo();
            % clear hidden state
            for i = 1 : numel(obj.S)
                obj.S{i}.clear();
            end
            % extract frames from packages
            if isempty(varargin)
                for i = 1 : numel(obj.O)
                    obj.O{i}.extract();
                end
            else
                for i = 1 : numel(obj.O)
                    obj.O{i}.extract(varargin{i});
                end
            end
            % process frames one by one
            for t = 1 : obj.pkginfo.nframe
                % send frame to kernel
                for i = 1 : numel(obj.O)
                    obj.O{i}.sendFrame();
                end
                % update state in kernel
                for i = 1 : numel(obj.S)
                    obj.S{i}.backward();
                end
                % process data by kernel
                obj.kernel.backward();
            end
            % compress frames into package
            varargout = cellfun(@compress, obj.I, 'UniformOutput', false);
            if nargout == 0
                for i = 1 : numel(obj.I)
                    obj.I{i}.send(varargout{i});
                end
            end
        end
        
        function obj = update(obj)
            if isa(obj.kernel, 'Evolvable')
                obj.kernel.update();
            end
            % NOTE: following code would update initial value of hidden
            %       state in optimization process. However, this part has
            %       not been well examinated.
            % for i = 1 : numel(obj.S)
            %     obj.S{i}.update();
            % end
        end
    end
    
    methods
        function obj = enablePrediction(obj, varargin)
            % NOTE: 1. create structure containing 'number of prediction',
            %          'number of input frame'
            %       2. check provide links to cover all input
        end
        
        function obj = disablePrediction(obj)
        end
    end
    
    methods
        function obj = RecurrentUnit(kernel, varargin)
            obj.kernel = kernel.recrtmode(obj.memoryLength).seal();
            % initialize access-point list for input/output
            apin  = obj.kernel.I;
            apout = obj.kernel.O;
            % create hidden state
            obj.S = cell(1, numel(varargin));
            for i = 1 : numel(obj.S)
                tnext = varargin{i}{1};
                tprev = varargin{i}{2};
                shape = varargin{i}{3};
                obj.S{i} = RecurrentState(obj, tnext, tprev, shape);
                apin(cellfun(@tprev.compare, apin)) = [];
            end
            % create input/output access-points
            obj.I = cellfun(@(ap) RecurrentAP(obj, ap), apin, ...
                'UniformOutput', false);
            obj.O = cellfun(@(ap) RecurrentAP(obj, ap), apout, ...
                'UniformOutput', false);
        end
    end
    
    properties (SetAccess = protected)
        kernel % instance of INTERFACE, who actually process the data
        I = {} % input access points set
        O = {} % output access points set
        S = {} % hidden states set
    end
    properties (Hidden)
        pkginfo
    end
    properties (Constant)
        memoryLength = 30
    end
    methods
        function set.I(obj, value)
            try
                assert(iscell(value));
                if isscalar(value)
                    assert(isa(value{1}, 'RecurrentAP'));
                else
                    for i = 1 : numel(value)
                        assert(isa(value{i}, 'RecurrentAP'));
                        value{i}.cooperate(i);
                    end
                end
                obj.I = value;
            catch
                error('ILLEGAL ASSIGNMENT');
            end
        end
        
        function set.O(obj, value)
            try
                assert(iscell(value));
                if isscalar(value)
                    assert(isa(value{1}, 'RecurrentAP'));
                else
                    for i = 1 : numel(value)
                        assert(isa(value{i}, 'RecurrentAP'));
                        value{i}.cooperate(i);
                    end
                end
                obj.O = value;
            catch
                error('ILLEGAL ASSIGNMENT');
            end
        end
    end
    
    methods (Static)
        function [refer, aprox] = debug()
            datasize  = 16;
            statesize = 16;
            nframe  = 7;
            nvalid  = 100;
            batchsize = 8;
            % create referent model
            refer = LSTM.randinit(datasize, statesize);
%             refer = SimpleRNN.randinit(datasize, statesize, 'sigmoid');
%             refer.blin = BilinearTransform.randinit(sizeinA, sizeinB, sizehid);
%             refer.model = RecurrentUnit(Model(refer.blin), {refer.blin.O, refer.blin.IA});
%             refer.model.enableLastFrameMode();
%             refer.actIn = Activation('ReLu');
%             refer.lin = LinearTransform.randinit(sizehid, sizeout);
%             refer.actOut = Activation('sigmoid');
%             refer.blin.O.connect(refer.actIn.I);
%             refer.actIn.O.connect(refer.lin.I);
%             refer.lin.O.connect(refer.actOut.I);
%             refer.model = RecurrentUnit( ...
%                 Model(refer.blin, refer.actIn, refer.lin, refer.actOut), ...
%                 {refer.actOut.O, refer.blin.IA});
            % create estimate model
            aprox = LSTM.randinit(datasize, statesize);
%             aprox = SimpleRNN.randinit(datasize, statesize, 'sigmoid');
%             aprox.blin = BilinearTransform.randinit(sizeinA, sizeinB, sizeout);
%             aprox.model = RecurrentUnit(Model(aprox.blin), {aprox.blin.O, aprox.blin.IA});
%             aprox.model.enableLastFrameMode();
%             aprox.actIn = Activation('ReLU');
%             aprox.lin = LinearTransform.randinit(sizehid, sizeout);
%             aprox.actOut = Activation('sigmoid');
%             aprox.blin.O.connect(aprox.actIn.I);
%             aprox.actIn.O.connect(aprox.lin.I);
%             aprox.lin.O.connect(aprox.actOut.I);
%             aprox.model = RecurrentUnit( ...
%                 Model(aprox.blin, aprox.actIn, aprox.lin, aprox.actOut), ...
%                 {aprox.actOut.O, aprox.blin.IA});
            % create validate data
            validsetInA = DataPackage(rand(datasize, nframe, nvalid), 1, true);
            validsetOut = refer.forward(validsetInA);
%             validsetInB = DataPackage(rand(statesize, nvalid), 1, false);
%             validsetInC = DataPackage(rand(statesize, nvalid), 1, false);
%             validsetOut = refer.forward(validsetInA, validsetInB, validsetInC);
            % define likelihood as optimization objective
            likelihood = Likelihood('mse');
            % display current status of estimation
            objval = likelihood.evaluate(aprox.forward(validsetInA).data, validsetOut.data);
%             objval = likelihood.evaluate( ...
%                 aprox.forward(validsetInA, validsetInB, validsetInC).data, ...
%                 validsetOut.data);
            disp('[Initial Error Distribution]');
            distinfo(abs(cat(2, refer.dump{:}) - cat(2, aprox.dump{:})), 'WEIGHTS', true);
%             distinfo(abs(refer.blin.weightA - aprox.blin.weightA), 'WEIGHT IN A', false);
%             distinfo(abs(refer.blin.weightB - aprox.blin.weightB), 'WEIGHT IN B', false);
%             distinfo(abs(refer.blin.bias - aprox.blin.bias),  'BIAS IN', false);
            disp(repmat('=', 1, 100));
            fprintf('Initial objective value : %.2e\n', objval);
            % optimize estimation by SGD
            for i = 1 : UMPrest.parameter.get('iteration')
                apkg = DataPackage(randn(datasize, nframe, batchsize), 1, true);
                opkg = refer.forward(apkg);
                ppkg = aprox.forward(apkg);
%                 bpkg = DataPackage(randn(statesize, batchsize), 1, false);
%                 cpkg = DataPackage(randn(statesize, batchsize), 1, false);
%                 opkg = refer.forward(apkg, bpkg, cpkg);
%                 ppkg = aprox.forward(apkg, bpkg, cpkg);
                aprox.backward(likelihood.delta(ppkg, opkg));
                aprox.update();
                objval = likelihood.evaluate(aprox.forward(validsetInA).data, validsetOut.data);
%                 objval = likelihood.evaluate( ...
%                     aprox.forward(validsetInA, validsetInB, validsetInC).data, ...
%                     validsetOut.data);
                fprintf('Objective Value after [%04d] turns: %.2e\n', i, objval);
%                 pause();
            end
%             objval = likelihood.evaluate( ...
%                 aprox.model.forward(validsetInA, validsetInB).data, ...
%                 validsetOut.data);
%             fprintf('Objective Value after [%04d] turns: %.2e\n', i, objval);
%             % show estimation error
%             distinfo(abs(refer.blin.weightA - aprox.blin.weightA), 'WEIGHT IN A', false);
%             distinfo(abs(refer.blin.weightB - aprox.blin.weightB), 'WEIGHT IN B', false);
%             distinfo(abs(refer.blin.bias - aprox.blin.bias),  'BIAS IN', false);
%             distinfo(abs(refer.lin.weight - aprox.lin.weight), 'WEIGHT HID', false);
%             distinfo(abs(refer.lin.bias - aprox.lin.bias), 'BIAS HID', false);
            % FOR LSTM
            distinfo(abs(cat(2, refer.dump{:}) - cat(2, aprox.dump{:})), 'WEIGHTS', true);
        end
    end
end
