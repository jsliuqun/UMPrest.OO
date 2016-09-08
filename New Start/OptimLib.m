% Colllection of functions those applies optimization
classdef OptimLib < handle
    methods (Static)
        function opt = minimize(objfunc, init, conf, varargin)
            opt = minFunc(objfunc, init, conf, varargin{:});
        end
        
        function conf = config(code)
            switch lower(code)
                case {'default'}
                    conf = struct( ...
                        'Method',      'cg',  ...
                        'Display',     'off', ...
                        'MaxIter',     17,    ...
                        'MaxFunEvals', 23);
                    
                case {'debug'}
                    conf = struct( ...
                        'Method',      'sd', ...
                        'Display',     'iter', ...
                        'MaxIter',     1e3, ...
                        'MaxFunEvals', 1e4);
            end
        end
    end
end
