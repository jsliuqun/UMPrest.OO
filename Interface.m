classdef Interface < handle
    % methods
    %     function connect(obj, anotherUnit)
    %         assert(numel(obj.O) == numel(anotherUnit.I), 'ILLEGAL OPERATION');
    %         arrayfun(@(i) obj.O(i).connect(anotherUnit.I(i)), 1 : numel(obj.O));
    %     end
    %     
    %     function oneway(obj, anotherUnit)
    %         assert(numel(obj.O) == numel(anotherUnit.I), 'ILLEGAL OPERATION');
    %         arrayfun(@(i) obj.O(i).addlink(anotherUnit.I(i)), 1 : numel(obj.O));
    %     end
    % end
    
    methods
        function obj = aheadof(obj, varargin)
            for i = 1 : numel(varargin)
                apto = varargin{i};
                % skip if when empty array
                if isempty(apto)
                    continue
                end
                % special cases
                if iscell(apto) && isscalar(apto)
                    apto = apto{1};
                elseif isa(apto, 'Interface') && isscalar(apto.O)
                    apto = apto.I{1};
                end
                assert(isa(apto, 'AccessPoint'), 'ILLEGAL OPERATION');
                apto.connect(obj.O{i});
            end
        end
        
        function obj = appendto(obj, varargin)
            for i = 1 : numel(varargin)
                apfrom = varargin{i};
                % skip if when empty array
                if isempty(apfrom)
                    continue
                end
                % special cases
                if iscell(apfrom) && isscalar(apfrom)
                    apfrom = apfrom{1};
                elseif isa(apfrom, 'Interface') && isscalar(apfrom.O)
                    apfrom = apfrom.O{1};
                end
                assert(isa(apfrom, 'AccessPoint'), 'ILLEGAL OPERATION');
                apfrom.connect(obj.I{i});
            end
        end
    end
    
    methods (Abstract)
        varargout = forward(obj, varargin)
        varargout = backward(obj, varargin)
    end
    
    properties (Abstract, SetAccess = protected)
        I, O % container of Input/Output AccessPoints
    end
end
