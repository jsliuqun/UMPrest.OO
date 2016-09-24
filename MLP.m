classdef MLP < SequentialModel
    methods
        function obj = MLP(inputSize, perceptronQuantityList, varargin)
            assert(not(isempty(perceptronQuantityList)), ...
                'UMPrest:ArgumentError', 'Quantity list of percetrons is invalid');
            
            obj = obj@SequentialModel();
            
            conf     = Config(varargin);
            hactType = conf.pop('HiddenLayerActType', 'ReLU');
            oactType = conf.pop('OutputLayerActType', 'Logistic');
            
            sizeList = [inputSize, perceptronQuantityList];
            for i = 2 : numel(sizeList)
                obj.appendUnit(Perceptron(sizeList(i-1), sizeList(i)));
            end
            
            obj.units(numel(obj)).actType = oactType;
            for i = numel(obj) - 1 : -1 : 1
                obj.units(i).actType = hactType;
            end
            
            conf.apply(obj);
        end
    end
    
    methods (Static)
        function debug()
            inputSize = 400;
            psizeList = [512, 1024, 376, 128, 10];
            hactType  = 'ReLU';
            oactType  = 'Sigmoid';
            
            % main work flow
            model = MLP(inputSize, psizeList, ...
                'HiddenLayerActType', hactType, ...
                'OutputLayerActType', oactType);
            % x = randn(inputSize, 1);
            % y = model.transform(x);
            % model.errprop(y);
            % model.update();
            datasource = load(UMPrest.path('data', 'tinytest'));
            ds = VideoDataset(MemoryDataBlock( ...
                MathLib.pack2cell(datasource.X'), ...
                StatisticCollector(), 'label', ...
                MathLib.pack2cell(MathLib.ind2tf(datasource.y, 1, 10))));
            model.likelihood = Likelihood('logistic');
            model.task = Task('classify');
            Trainer.minibatch(model, ds)
        end
    end
end