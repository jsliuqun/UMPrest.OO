classdef MIMOUnit < SimpleUnit
    methods
%         function varargout = propagate(obj, apin, apout, proc, varargin)
%             % clear CDINFO of parent unit
%             obj.pkginfo = UnitAP.initPackageInfo();
%             % get input package
%             if isempty(varargin)
%                 ipackage = cellfun(@pop, apin, 'UniformOutput', false);
%             else
%                 ipackage = varargin;
%             end
%             % unpack data from package
%             idata = cellfun(@(ap, pkg) ap.unpack(pkg), apin, ipackage, 'UniformOutput', false);
%             % process the data
%             odata = cell(1, numel(apout));
%             [odata{:}] = proc(obj.pkginfo.class, idata{:});
%             % packup data into package
%             varargout = cellfun(@(ap, d) ap.packup(d), apout, odata, 'UniformOutput', false);
%             % send package if no output argument
%             if nargout == 0
%                 for i = 1 : numel(apout)
%                     apout{i}.send(varargout{i});
%                 end
%             end
%         end
        
        function varargout = forward(obj, varargin)
            obj.pkginfo = UnitAP.initPackageInfo();
            % get input package from cache
            if isempty(varargin)
                varargin = cell(1, numel(obj.I));
                for i = 1 : numel(obj.I)
                    varargin{i} = obj.I{i}.pop();
                end
            end
            % unpack input data from package
            datain = cell(1, numel(obj.I));
            for i = 1 : numel(obj.I)
                datain{i} = obj.I{i}.unpack(varargin{i});
            end
            % process input data
            dataout = cell(1, numel(obj.O));
            [dataout{:}] = obj.process(obj.pkginfo.class, datain{:});
            % packup output data into package
            varargout = cell(1, numel(obj.O));
            for i = 1 : numel(obj.O)
                varargout{i} = obj.O{i}.packup(dataout{i});
            end
            % send package when no output argument given
            if nargout == 0
                for i = 1 : numel(obj.O)
                    obj.O{i}.send(varargout{i});
                end
            end
        end
        
        function varargout = backward(obj, varargin)
            obj.pkginfo = UnitAP.initPackageInfo();
            % get output package from cache
            if isempty(varargin)
                varargin = cell(1, numel(obj.O));
                for i = 1 : numel(obj.O)
                    varargin{i} = obj.O{i}.pop();
                end
            end
            % unpack output data from package
            dataout = cell(1, numel(obj.O));
            for i = 1 : numel(obj.O)
                dataout{i} = obj.O{i}.unpack(varargin{i});
            end
            % process output data
            datain = cell(1, numel(obj.I));
            [datain{:}] = obj.invproc(obj.pkginfo.class, dataout{:});
            % packup input data into package
            varargout = cell(1, numel(obj.I));
            for i = 1 : numel(obj.I)
                varargout{i} = obj.I{i}.packup(datain{i});
            end
            % send package when no output argument given
            if nargout == 0
                for i = 1 : numel(obj.I)
                    obj.I{i}.send(varargout{i});
                end
            end
        end
    end
    
    properties (SetAccess = protected)
        I = {} % input access point set
        O = {} % output access point set
    end
    methods
        function set.I(obj, value)
            try
                assert(iscell(value) && not(isscalar(value)));
                for i = 1 : numel(value)
                    assert(isa(value{i}, 'UnitAP'));
                    value{i}.cooperate(i);
                end
                obj.I = value;
            catch
                error('ILLEGAL ASSIGNMENT');
            end
        end
        
        function set.O(obj, value)
            try
                assert(iscell(value) && not(isscalar(value)));
                for i = 1 : numel(value)
                    assert(isa(value{i}, 'UnitAP'));
                    value{i}.cooperate(i);
                end
                obj.O = value;
            catch
                error('ILLEGAL ASSIGNMENT');
            end
        end
    end
end
