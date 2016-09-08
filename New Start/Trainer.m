classdef Trainer < handle
    methods (Static)
        function conf = getConfig(trainMethod)
            param = UMPrest.parameter();
            switch lower(trainMethod)
                case {'minibatch'}
                  conf = Config( ...
                      'divisionRatio',    [0.6, 0.1, 0.3], ...
                      'epoch',            param.get('epoch', 10), ...
                      'batchsize',        param.get('batchsize', 32), ...
                      'validateInterval', param.get('validateInterval', 1000));
            end
        end
    end
    
    methods (Static)
        function varargout = minibatch(model, dataset, varargin)
            conf = Trainer.getConfig('minibatch');
            conf.update(varargin{:});
            % PROBLEM: cannot deal with unlimited data source
            [trainset, validset, testset] = dataset.subsets(conf.get('divisionRatio'));
            % gather validate and test data
            vdata = validset.next(validset.volumn());
            tdata = testset.next(testset.volumn());
            
            log = Logger(model, conf.get('displayMode', 'shell'));
            log.initRecord('ValidSet', vdata, 'interval', conf.get('validateInterval'));
            log.initRecord('TestSet', tdata);
           
            for ep = 1 : conf.get('epoch')
                for bat = 1 : ceil(trainset.volumn() / conf.get('batchsize'))
                    model.trainproc(trainset.next(conf.get('batchsize')));
                    log.record('ValidSet', vdata); 
                    % TBC : modify model parameters according to validation result
                end
                log.record('TestSet', tdata);
            end
            
            if nargout > 0
                varargout{1} = log;
            end
        end
    end
end