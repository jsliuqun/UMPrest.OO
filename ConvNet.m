% CNN is an abstraction of Convolutional Neural Network.
%
% MooGu Z. <hzhu@case.edu>
% Feb 18, 2016

classdef ConvNet < LModel
    % ============= LMODEL IMPLEMENTATION =============
    methods
        function output = produce(obj, input)
        end
        
        function value = evaluate(obj, output, target)
        end
        
        function signal = impulse(obj, output, target)
        end
        
        function evolve(obj, signal, opt)
        end
    end
    
    % ============= CONSTRUCTOR =============
    methods
        function obj = ConvNet(dimin, dimout, nfilters, szfilters, ...
                           activateType, poolingType, normalizeType)
            nunit = numel(nfilterArray);
            
            % set default value
            if ~exist('activateType', 'var'),  activateType = 'sigmoid'; end
            if ~exist('poolingType', 'var'),   poolingType  = 'max';     end
            if ~exist('normalizeType', 'var'), normalizeType = 'norm';   end
            
            % check validity of input arguments
            assert(numel(dimin) == 3);
            assert(numel(dimout) == 1);
            assert(numel(szfilters) == nunit);
            assert((iscellstr(activateType) && numel(activateType) == nunit+1) ...
                   || ischar(activateType));
            assert((iscellstr(poolingType) && numel(poolingType) == nunit) ...
                   || ischar(poolingType));
            assert((iscellstr(normalizeType) && numel(normalizeType) == nunit+1) ...
                   || ischar(normalizeType));
            
            % construct convolutional layers
            datadim = dimin;
            for i = 1 : nunit
                obj.addUnit(ConvPerceptron( ...
                    nfilters(i), ...
                    szfilter(i), ...
                    datadim(3), ...
                    ite(ischar(activateType), activateType, activateType{i}), ...
                    ite(ischar(poolingType), poolingType, poolingType{i}), ...
                    ite(ischar(normalizeType), normalizeType, normalizeType{i}));
                datadim = obj.U(i).dimout(datadim);
            end
            % construct full-connected layer
            obj.addUnit(Perceptron( ...
                datadim, ...
                dimout, ...
                ite(ischar(activateType), activateType, activateType{end}));
        end
    end
end
