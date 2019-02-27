classdef PPMatLib < handle
%classdef PPMatLib < handle
%This object is used as a collection of materials objects.  To add a new
%material object it must have the filename PPMatXXXX where XXXX is the
%specific formulation of the material and it must have PPMat as its super
%class.
%
%Usage of PPMatLib
%
%Properties:
%   NumMat     - Number of materials currently in the library
%   Params     - List of all parameters of the material types currently
%                in the library
%   MatList    - List of materials currently in the library
%   GUIModFlag - Set to true if Library is modified under GUI Control.
%                Must be manually reset.
%
%Access Methods:
%   MatLib(index)  - Returns a new MatLib comprised of materials 
%                    identified in index
%   MatLib.Param   - Same as GetParam method below
%
%Launch GUI:
%   ShowTable()         - Launch GUI to display/modify materials table
%   DefineNewMaterial() - Launch GUI to add a new material.
%
%Methods:
%   GetParam (Param)   - Return vector of parameter values for all 
%                        materials. Materials that do not define that 
%                        parameter will have NaN
%   GetMatName (Name)  - Returns the material object that matches that
%                        name
%   GetMatNum (Number) - Returns the material object that matches that
%                        index into the library
%   ParamDesc (Param)  - Returns description of that parameter
%   AddMatl (MatObj)   - Adds the material defined in MatObj to the 
%                        library
%   GetMatTypesAvail() - Returns a list of all known material types
%   GetParamAvail()    - Returns list of all parameters in all known
%                        material types

%    properties (Access=public)
%        Name    {mustBeChar(Name)} 
%    end
    
    properties (Access = protected)
        PropValPairs = {}
        iMatObjList
        iParamList 
        iFilename
        iSource
        iMatTypeList
        iNameList
        iPropVals=[];
        ErrorText='';
        iNewMatF
        iMatableF
    end
    
    properties
        GUIModFlag=false;
    end
    
    properties (Access=public, Dependent)
        NumMat
        Params
        MatList
        Source
    end

    methods (Access = protected)
        function PopulateProps(obj)
            iPropValsBuf=NaN(obj.NumMat, length(obj.iParamList));
            if strcmpi(obj.iParamList{1},'Name') && strcmpi(obj.iParamList{2},'Type')
                for Iprop=3:length(obj.iParamList)
                    for Imat=1:obj.NumMat
                        ThisMat=obj.GetMatNum(Imat);
                        if isprop(ThisMat,obj.iParamList{Iprop})
                            iPropValsBuf(Imat,Iprop)=ThisMat.(obj.iParamList{Iprop});
                        end
                    end
                end
                obj.iPropVals=iPropValsBuf;
            else
                obj.AddError('First property name MUST be "Name" and second MUST be "Type"')
                obj.ShowErrorText;
            end
        end
        
        function ClearProps(obj)
            obj.iPropVals=[];
        end
        function UpdateInternalVars(obj)
            MatTypeList={};
            MatNameList={};
            MatParmList={};
            for I=1:obj.NumMat
                TempMat=obj.GetMatNum(I);
                MatTypeList{I}=TempMat.Type;
                MatNameList{I}=TempMat.Name;
                MatParmList=[MatParmList; TempMat.ParamList];
            end
            MatTypeList=unique(MatTypeList);
            MatParmList=unique(MatParmList);
            AbstractFields=fields(PPMat);
            for I=1:length(AbstractFields)
                MatParmList=MatParmList(~strcmpi(MatParmList,AbstractFields(I)));
            end
            obj.iParamList=[AbstractFields; MatParmList];
            obj.iMatTypeList=MatTypeList;
            obj.iNameList=MatNameList;
            obj.PopulateProps;
        end
        function CheckProperties (obj, MfileClass)

        end
        function AddError(obj,Text) %Empty clears the error list
            if ~exist('Text','var')
                obj.ErrorText='';
            else
                obj.ErrorText=sprintf('%s\n%s',obj.ErrorText,Text);
            end
        end
    end
    methods (Static)
        function Types=GetMatTypesAvail
            LibPath=mfilename('fullpath');
            LibPath=strrep(LibPath,mfilename,'');
            F=dir([LibPath 'PPMat*.m']);
            Types={};
            for I=1:length(F)
                MatFile=F(I).name;
                MatFile=MatFile(1:end-2);
                if ~strcmp(MatFile,'PPMatLib') & ~strcmp(MatFile,'PPMat')
                    eval(sprintf('TempMat=%s;',MatFile));
                    Types{end+1}=TempMat.Type;
                end
            end
            N=strcmpi('Null',Types);
            if ~isempty(find(N))
                Types=Types(~N);
                Types=['Null' Types];
            end
                
        end
        
        function Params=GetParamAvail
            Params={};
            MatTypes=PPMatLib.GetMatTypesAvail();
            for I=1:length(MatTypes)
                eval(['Mat=PPMat' MatTypes{I} '();']);
                Params=[Params; fields(Mat)];
            end
            Params=unique(Params);
            AbstractFields=fields(PPMat);
            for I=1:length(AbstractFields)
                Params=Params(~strcmpi(Params,AbstractFields(I)));
            end
            Params=[AbstractFields; Params];            
        end
    end
    
    methods
        function OutParamVec = GetParamVector (obj, Param)
            %OutParamVec = GetParamVector (obj, Param)
            %High speed return of parameter vector
            if isempty(obj.iPropVals)
                obj.PopulateProps;
            end
            Iprop=find(strcmpi(obj.iParamList, Param));
            OutParamVec=obj.iPropVals(:,Iprop);
            OutParamVec=reshape(OutParamVec,[],1);
        end
        
%         function varargout=subsref(obj,s) 
%            switch s(1).type
%               case '.'
%                  if length(s) == 1 & ~isprop(obj,s.subs)
%                     % Implement obj.PropertyName
%                      varargout{1}=obj.GetParam(s.subs);
%                  elseif length(s) == 2 && strcmp(s(2).type,'()') && any(strcmpi(obj.iParamList,s(1).subs)) 
%                     % Implement obj.PropertyName(indices)
%                       List=obj.GetParam(s(1).subs);
%                       varargout{1}=List(s(2).subs{1});
%                  else
%                     [varargout{1:nargout}] = builtin('subsref',obj,s);
%                  end
%               case '()'
%                  if length(s) == 1
%                     % Implement obj(indices)
%                     TempOut=PPMatLib;
%                     for Mi=reshape(s.subs{1},1,[])
%                         TempOut.AddMatl(obj.iMatObjList{Mi})
%                     end
%                     varargout{1}=TempOut;
%                  elseif length(s) == 2 && strcmp(s(2).type,'.')
%                      Implement this as a buffered property that is contruced on first use that gets wiped out when material changed/added
%                      %Algorithm will be to construct material propery
%                      %vectors on first call.  Then destroy them with any
%                      %call to add/delete/replace material
%                      %Vectors will be comprised of two parts.
%                      %PropName - Cell Array of property name
%                      %PropValue{Property Number} - Cell Array
%                     % Implement obj(ind).PropertyName
%                     TempLib=PPMatLib;
%                     for Mi=reshape(s(1).subs{1},1,[])
%                         TempLib.AddMatl(obj.iMatObjList{Mi});
%                     end
%                     varargout{1}=TempLib.GetParam(s(2).subs);
% %                  elseif length(s) == 3 && strcmp(s(2).type,'.') && strcmp(s(3).type,'()')
% %                     % Implement obj(indices).PropertyName(indices)
% %                     ...
%                  else
%                     % Use built-in for any other expression
%                     [varargout{1:nargout}] = builtin('subsref',obj,s);
%                  end
% %               case '{}'
% %                  if length(s) == 1
% %                     % Implement obj{indices}
% %                     ...
% %                  elseif length(s) == 2 && strcmp(s(2).type,'.')
% %                     % Implement obj{indices}.PropertyName
% %                     ...
% %                  else
% %                     % Use built-in for any other expression
% %                     [varargout{1:nargout}] = builtin('subsref',obj,s);
% %                  end
%               otherwise
%                  error('Not a valid indexing expression')
%            end
% 
%        end

        function OutParam=GetParam(obj, Param)
            AvailParams=obj.Params;
            if isempty(find(strcmp(AvailParams, Param),1))
                obj.AddError(sprintf('Parameter ''%s'' doesn''t exist in this MatLib',Param))
                OutParam=[];
            else
                IsNumericParam=true;
                for Imat=1:obj.NumMat
                    MatObj=obj.GetMatNum(Imat);
                    if isprop(MatObj, Param)
                        OutParam{Imat}=getfield(MatObj,Param);
                        if ~isnumeric(OutParam{Imat})
                            IsNumericParam=false;
                        end
                    else
                        OutParam{Imat}=NaN;
                    end
                end
                if IsNumericParam
                    OutParam=cell2mat(OutParam);
                end
            end
            OutParam=reshape(OutParam,[],1);
            obj.ShowErrorText
        end
        function ShowErrorText(obj, dest)
            if ~exist('dest')
                dest='';
            end
            if ~isempty(obj.ErrorText)
                if strcmpi(dest,'gui')
                    msgbox(obj.ErrorText, 'Warning')
                else
                    warning(obj.ErrorText)
                end
                obj.AddError();
            end
        end
        function MatObj=GetMatName(obj, MatName)
            obj.AddError();
            MatNum=find(strcmpi(obj.MatList,MatName));
            if ~isempty(MatNum)
                MatObj=obj.iMatObjList{MatNum};
            else
                obj.AddError(sprintf('Material named ''%s'' is not in library',MatName));
            end
            obj.ShowErrorText;
        end
        function MatObj=GetMatNum(obj, MatNum)
            obj.AddError();
            if MatNum<=obj.NumMat
                MatObj=obj.iMatObjList{MatNum};
            else
                obj.AddError(sprintf('Material number ''%.0f'' does not exist.',MatNum));
            end
            obj.ShowErrorText;
        end
        function OutText=ParamDesc(obj, Param)
            MatNum=1;
            while MatNum <= length(obj.iMatObjList)
                OutText=obj.iMatObjList{MatNum}.ParamDesc(Param);
                if ~isempty(OutText)
                    MatNum=length(obj.iMatObjList)+1;
                else
                    MatNum=MatNum+1;
                end
                
            end
            if isempty(OutText)
                AddError(sprintf('No descriptor found for %s',Param));
                obj.ShowErrorText;
            end
        end
        function set.Source(obj, Text)
            obj.iSource=Text;
        end
        function Text=get.Source(obj)
            Text=obj.iSource;
        end
        function N=get.NumMat(obj)
            N=length(obj.iMatObjList);
        end
        function P=get.Params(obj)
            P=reshape(obj.iParamList,[],1);
        end
        function M=get.MatList(obj)
            for I=1:length(obj.iMatObjList)
                M{I}=obj.iMatObjList{I}.Name;
            end
            
        end
        function obj =PPMatLib(varargin)
            obj.iParamList={}; 
            obj.iFilename='';
            obj.iMatTypeList={};
            obj.iNameList={};
            obj.iMatObjList={};
            if nargin>=1 && (any(strcmp(superclasses(varargin{1}),'PPMat')))
                for Ai=1:nargin
                    if any(strcmp(superclasses(varargin{Ai}),'PPMat'))
                        obj.AddMatl(varargin{Ai})
                    else
                        obj.AddError('For PPMatLib(Mat1, Mat2, Mat3) form all arguments must be a material class.')
                        obj.AddError(sprintf('Argument %.0f is of type',class(varargin{Ai})))
                    end
                end
            elseif nargin==1 && strcmp(class(varargin{1}),'PPMatLib')
                OldLib=varargin{1};
                for I=1:OldLib.NumMat
                    obj.AddMatl(OldLib.GetMatNum(I));
                end
            elseif nargin>=1
                obj.AddError('Unknown constructor argument.')
                disp(varargin);
            end
            obj.ShowErrorText;
            %if nargin=1 & 
        end
        
        function DefineNewMaterial (obj, Action, varargin)
            if ~exist('Action')
                Action='Init';
            end
            switch lower(Action)

                case 'init'
                    if ishandle(obj.iNewMatF) & isvalid(obj.iNewMatF)
                        delete(obj.iNewMatF)
                    end
                    NP=[0.1 0.95 0.1 0.1];
                    FS=12;
                    LongestString='Nucleation Delta TempMMMM';
                    obj.iNewMatF=figure('name','Define Material','menu','none','toolbar','none','unit','normal','numbertitle','off');
%DEBUG                    set(obj.iNewMatF,'windowstyle','modal');
                    P=get(obj.iNewMatF,'posit');
                    set(obj.iNewMatF,'posit',[P(1) .15 P(3) .8]);
                    Temp=uicontrol('unit','normal','style','edit','string',LongestString,'fontsize',FS);
                    E=get(Temp,'extent');
                    delete(Temp);
                    NP(3:4)=E(3:4);
                    Close_CB=@(H,A)delete(obj.iNewMatF);
                    OK_CB=@(H,A)obj.DefineNewMaterial('OK',H,A);
                    MatType_CB=@(H,A)obj.DefineNewMaterial('PopParms',H,A);
                    H.OKBtn=uicontrol('unit','normal','style','pushbutton','string','OK','posit',[0.3 0.1 0.19 0.05],'fontsize',FS,'callback',OK_CB);
                    H.CnBtn=uicontrol('unit','normal','style','pushbutton','string','Cancel','posit',[0.6 0.1 0.19 0.05],'fontsize',FS,'callback',Close_CB);
                    H.Name=uicontrol('unit','normal','style','text','string','Name:','posit',NP,'fontsize',FS,'horiz','left');
                    H.NameE=uicontrol('unit','norma','style','edit','string','','posit',[NP(1)+NP(3)+.01 NP(2) 1-NP(1)-NP(3)-.05 NP(4)],'fontsize',FS,'horizon','left','user','Name');
                    H.Type=uicontrol('unit','normal','style','text','string','Type:','posit',[NP(1) NP(2)-E(4)*1.05 E(3) E(4)],'fontsize',FS,'horiz','left');
                    PopParms=@(A,B)obj.DefineNewMaterial('PopParms');
                    H.TypeE=uicontrol('unit','norma','style','popup','string',obj.GetMatTypesAvail,'posit',[NP(1)+NP(3)+.01 NP(2)-E(4)*1.05 1-NP(1)-NP(3)-.05 NP(4)] ...
                                     ,'fontsize',FS,'horizon','left' ...
                                     ,'callback',MatType_CB ...
                                     ,'user','type' ...
                                     );
                    H.ParamL=[];
                    H.ParamE=[];
                    set(obj.iNewMatF,'user',H);
                    MatType_CB(H.TypeE,[]);
                case 'edit'
                    if length(varargin)==1
                        MaterialNumber=varargin{1};
                    else
                        error('invalid number of arguments.')
                    end
                    obj.DefineNewMaterial('init');
                    H=get(obj.iNewMatF,'user');
                    ThisMat=obj.GetMatNum(MaterialNumber);
                    set(H.OKBtn,'user',MaterialNumber);
                    set(H.NameE,'string',ThisMat.Name);
                    set(H.TypeE,'value',find(strcmpi(ThisMat.Type,get(H.TypeE,'string'))));
                    obj.DefineNewMaterial('popparms',H.TypeE,[])
                    H=get(obj.iNewMatF,'user');
                    for I=1:length(H.ParamE)
                        ParamName=get(H.ParamE(I),'user');
                        set(H.ParamE(I),'string',num2str(ThisMat.(ParamName)));
                    end
                    
                    
                case 'popparms'
                    handle=varargin{1};
                    %action=varargin{2};
                    Types=get(handle,'string');
                    ThisType=Types{get(handle,'value')};
                    eval(['NewMat=PPMat' ThisType ';' ]);
                    H=get(get(handle,'parent'),'user');
                    
                    %disp(['Setting material type ' ThisType ':'])
                    NPl=get(H.Name,'posit');
                    NPl_delta=get(H.Name,'posit')-get(H.Type,'posit');
                    FS=get(H.Name,'fontsize');
                    
                    if strcmpi(ThisType,'null')
                        ParamList={};
                     else
                        ParamList=NewMat.ParamList;
                        ParamList=ParamList(~strcmpi(ParamList,'SClass'));
                    end
                    OldParam={};
                    if ~isempty(H.ParamL)
                        for I=1:length(H.ParamL)
                            OldParam{I}=get(H.ParamE(I),'user');
                            OldValue{I}=get(H.ParamE(I),'string');
                            delete(H.ParamL(I));
                            delete(H.ParamE(I));
                        end
                        H.ParamL=[];
                        H.ParamE=[];
                    end
                    
                    for I=1:length(ParamList)
                        %disp(['Setting ' ParamList{I}])
                        Posit=NPl - (I+1)*NPl_delta - [0 .005 0 0 ];
                        Desc=NewMat.ParamDesc(ParamList{I});
                        H.ParamL(I)=uicontrol('unit','normal','style','text','string',[Desc ':'],'posit',Posit,'fontsize',FS,'horiz','left');
                        
                        Posit=[Posit(1)+Posit(3)+0.01 Posit(2) 1-Posit(1)-Posit(3)-0.05 Posit(4)]; %[NP(1)+NP(3)+.01 NP(2) 1-NP(1)-NP(3)-.05 NP(4)]
                        H.ParamE(I)=uicontrol('unit','norma','style','edit','string','','posit',Posit,'fontsize',FS,'horizon','left','user',ParamList{I});
                        OldParmI=find(strcmpi(OldParam,ParamList{I}));
                        if ~isempty(OldParmI)
                            set(H.ParamE(I),'string',OldValue{OldParmI})
                        end
                    end
                    set(get(handle,'parent'),'user',H);
                case 'ok'
                    Success=true;
                    handle=varargin{1};
                    H=get(get(handle,'parent'),'user');
                    Types=get(H.TypeE,'string');
                    ThisType=Types{get(H.TypeE,'value')};
                    eval(['NewMat=PPMat' ThisType ';' ]);
                    Name=get(H.NameE,'string');
                    ArgList=sprintf('''Name'', ''%s'' ',Name);
                    ParamList=NewMat.ParamList;
                    if strcmpi(NewMat.Type,'null')
                        ParamList={};
                    end
                    for I=1:length(ParamList)
                        Value=get(H.ParamE(I),'string');
                        if isempty(Value)
                            obj.AddError(sprintf('Parameter "%s" is empty.',ParamList{I}));
                            Value='NaN';
                            Success=false;
                        elseif isempty(str2num(Value))
                            obj.AddError(sprintf('Parameter "%s" is "%s" but must be a number.',ParamList{I},Value));
                            Value='NaN';
                            Success=false;
                        end
                        ArgList=sprintf('%s, ''%s'', %s ',ArgList, ParamList{I}, Value);
                    end
                    eval(['NewMat=PPMat' ThisType '(' ArgList ');' ]);
                    %assignin('base','NewMat',NewMat)
                    obj.ShowErrorText('gui');
                    OldMatNum=get(H.OKBtn,'user');
                    if isempty(OldMatNum) && Success
                        obj.AddMatl(NewMat);
                    elseif Success
                        Success=obj.ReplMatl(OldMatNum,NewMat);
                    end
                    if Success
                        delete(obj.iNewMatF)
                        obj.iSource=[obj.iSource '*'];
                        obj.iNewMatF=[];
                        obj.GUIModFlag=true;
                    else
                        %obj.AddError('Material modifications will be discarded.')
                        obj.ShowErrorText('gui');
                    end
                    obj.ClearProps
                otherwise
                    obj.AddError(sprintf('Unknown action for DefineNewMaterial function "%s"',Action))
                obj.ShowErrorText;
            end
            
        end
        
        function ShowTable (obj, Action, varargin)
            if ~exist('Action')
                Action='init';
            end
            switch lower(Action)
                case 'init'
                    if ishandle(obj.iMatableF) & isvalid(obj.iMatableF)
                        delete(obj.iMatableF)
                    end
                    NP=[0.1 0.95 0.1 0.1];
                    FS=12;
                    obj.iMatableF=figure('name','Material Library','menu','none','toolbar','none','unit','normal','numbertitle','off');
%DEBUG                    set(obj.iMatableF,'windowstyle','modal');
                    %P=get(obj.iNewMatF,'posit');
                    set(obj.iMatableF,'posit',[.2 .2 .7 .45]);
                    
                    Cancel_CB=@(H,A)obj.ShowTable('Cancel',H,A);
                    OK_CB=@(H,A)obj.ShowTable('OK',H,A);
                    SelectCell_CB=@(H,A)obj.ShowTable('CellEdit',H,A);
                    MatType_CB=@(H,A)obj.ShowTable('PopParms',H,A);
                    Delete_CB=@(H,A)obj.ShowTable('DeleteRow',H,A);
                    Insert_CB=@(H,A)obj.ShowTable('InsertRow',H,A);
                    Sort_CB=@(H,A)obj.ShowTable('SortRow',H,A);
                    Load_CB=@(H,A)obj.ShowTable('Load',H,A);
                    Save_CB=@(H,A)obj.ShowTable('Save',H,A);
                    Help_CB=@(H,A)obj.ShowTable('Help',H,A);
                    OrigMatLib=PPMatLib;
                    for I=1:obj.NumMat
                        OrigMatLib.AddMatl(obj.GetMatNum(I));
                    end
                    OrigMatLib.iSource=obj.iSource;
                    setappdata(obj.iMatableF,'OrigMatLib',OrigMatLib);
                    Pl=0.2;
                    Pb=0.01;
                    Pw=0.08;
                    Ph=0.06;
                    H.Text(1)=uicontrol('unit','normal','style','text','string','Data from Memory','posit',[0 .95 1 .05],'fontsize',FS,'horizont','center');
                    H.Text(2)=uicontrol('unit','normal','style','text','string','Click on a material name to edit its properties','posit',[0 .90 1 .05],'fontsize',FS,'horizont','center');
                    H.HelpBtn=uicontrol('unit','norma','style','pushbutton','string','Help','position',[1-Pw 1-Ph Pw*.9 Ph*.8],'fontsize',FS,'Callback',Help_CB);
                    H.Table=uitable('unit','normal','posit',[0.01 0.15 .98 .75],'rowname','','cellselectioncallback',SelectCell_CB);
                    H.LoadBtn=uicontrol('unit','norma','style','pushbutton','string','Import','position',[Pl Pb Pw*.9 Ph*.8],'fontsize',FS,'Callback',Load_CB);
                    H.SaveBtn=uicontrol('unit','norma','style','pushbutton','string','Export','position',[Pl Pb+Ph Pw*.9 Ph*.8],'fontsize',FS,'Callback',Save_CB);
                    H.OKBtn=uicontrol('unit','normal','style','pushbutton','string','OK', 'posit', [Pl+Pw*6 Pb Pw*.9 Ph*.8],'fontsize',FS,'callback',OK_CB);
                    H.CnBtn=uicontrol('unit','normal','style','pushbutton','string','Cancel', 'posit', [Pl+Pw*6 Pb+Ph Pw*.9 Ph*.8],'fontsize',FS,'callback',Cancel_CB);
                    H.DeleteBtn=uicontrol('unit','norma','style','pushbutton','string','Delete','position',[Pl+Pw*2 Pb Pw*.9 Ph*.8],'fontsize',FS,'Callback',Delete_CB);
                    H.InsertBtn=uicontrol('unit','norma','style','pushbutton','string','Insert','position',[Pl+Pw*2 Pb+Ph Pw*.9 Ph*.8],'fontsize',FS,'Callback',Insert_CB);
                    H.SortBtn=uicontrol('unit','norma','style','pushbutton','string','Sort','position',[Pl+Pw*4 Pb+Ph Pw*.9 Ph*.8],'fontsize',FS,'Callback',Sort_CB);
                    H.FieldList=uicontrol('unit','norma','style','popup','string','Insert','position',[Pl+Pw*4 Pb Pw*.9 Ph*.8],'fontsize',FS);%,'Callback',Insert_CB);
%                    H.DeleteBtn=uicontrol('unit','normal','style','pushbutton','string','OK','posit',[0.3 0.1 0.19 .05],'fontsize',FS,'callback',OK_CB);
%                    H.CnBtn=uicontrol('unit','normal','style','pushbutton','string','Cancel','posit',[0.6 0.1 0.19 0.05],'fontsize',FS,'callback',Close_CB);
%                    H.Name=uicontrol('unit','normal','style','text','string','Name:','posit',NP,'fontsize',FS,'horiz','left');
%                    H.NameE=uicontrol('unit','norma','style','edit','string','','posit',[NP(1)+NP(3)+.01 NP(2) 1-NP(1)-NP(3)-.05 NP(4)],'fontsize',FS,'horizon','left');
%                    H.Type=uicontrol('unit','normal','style','text','string','Type:','posit',[NP(1) NP(2)-E(4)*1.05 E(3) E(4)],'fontsize',FS,'horiz','left');
%                    PopParms=@(A,B)obj.DefineNewMaterial('PopParms');
%                    H.TypeE=uicontrol('unit','norma','style','popup','string',obj.GetMatTypesAvail,'posit',[NP(1)+NP(3)+.01 NP(2)-E(4)*1.05 1-NP(1)-NP(3)-.05 NP(4)] ...
%                                     ,'fontsize',FS,'horizon','left' ...
%                                     ,'callback',MatType_CB ...
%                                     );

                    set(obj.iMatableF,'user',H);
                    obj.ShowTable('PopulateTable')
                case 'help'
                    Text={};
                    Text{end+1}=['This Material Library (MatLib) is designed to work with ParaPower but.' ...
                                 'can be used independently.  All functionality is contained ' ...
                                 'with the PPMatLib.m file.  New materials can be created by ' ...
                                 'defining PPMatXXXXX.m objects.  The MatLib object is a handle '...
                                 'class object and thus is persistent and exists as a pointer.'];
                    Text{end+1}='';
                    Text{end+1}=['The object can be loaded and saved just as any other MATLAB object.' ...
                                 'However the PPMatLib.m must be accessible to enable full functionality.'];
                    Text{end+1}='';
                    Text{end+1}='Output of help PPMatLib:';
                    Text{end+1}=help('PPMatLib');
                    TextOutput=''; 
                    
                    for I=1:length(Text)
                        TextOutput=[TextOutput Text{I}  char(10)];
                    end
                    
                    H=msgbox(TextOutput,'Help','modal');
                    P=get(H,'posit');
                    set(H,'posit'   , P.* [1 1 1.3 1]);
                case 'populatetable'
                    H=get(obj.iMatableF,'user');
                    ColNames={};
                    if obj.NumMat==0    
                        TempMat=PPMat;
                        Params=properties(TempMat);
                        for I=1:length(Params)
                            ColNames{I+1}=TempMat.ParamDesc(Params{I});
                        end
                    else
                        Params=obj.Params;
                        for I=1:length(Params)
                            ColNames{I+1}=obj.ParamDesc(Params{I});
                        end
                    end
                    ColNames{1}='Del';
                    set(H.Table,'ColumnName',ColNames);
                    set(H.FieldList,'string',ColNames(2:end));
                    Data={};
                    for I=1:obj.NumMat
                        Mat=obj.GetMatNum(I);
                        MatProps=properties(Mat);
                        Data{I,1}=false;
                        for J=1:length(MatProps)
                            MatProps(J);
                            ColNum=find(strcmpi(Params,MatProps{J}))+1;
                            if isempty(ColNum)
                                Data{I,ColNum}='';
                            else
                                Data{I,ColNum}=Mat.(MatProps{J});
                            end
                        end
                    end
                    set(H.Table,'data',Data)
                    set(H.Table,'columnformat',{'logical'})
                    set(H.Table,'columneditable',[true false(1,length(ColNames))]);
                    S=get(H.Text(1),'string');
                    if length(obj.iSource)>2 && strcmp(obj.iSource(end-1:end),'**')
                        obj.iSource=obj.iSource(1:end-1);
                    end
                    if isempty(obj.iSource)
                        set(H.Text(1),'string',S);
                    else
%                         Si=strfind(S,',');
%                         if isempty(Si)
%                             Si=length(S)+1;
%                         end
                        set(H.Text(1),'string',['Source: ',obj.iSource]);
                    end
                    set(obj.iMatableF,'user',H);
                case 'celledit'
                    H=varargin{1};
                    A=varargin{2};
                    H=get(get(H,'parent'),'user');
                    Index=A.Indices;
                    ClickIndex=find(strcmpi('Name',get(H.Table,'columnname')));
                    if length(Index(:,2))==1 & Index(2)==ClickIndex
                        obj.DefineNewMaterial('edit',Index(1));
                        uiwait(obj.iNewMatF)
                        D=get(H.Table,'data'); set(H.Table,'data',[],'data',D)
                        obj.ShowTable('PopulateTable')
                    end
                case 'ok'
                    handle=varargin{1};
                    H=get(get(handle,'parent'),'user');
                    obj.ShowErrorText;
                    delete(obj.iMatableF)
                    obj.iMatableF=[];
                    if length(findobj) > 1
                        uiresume
                    end
                case 'load'
                    handle=varargin{1};
                    H=get(get(handle,'parent'),'user');
                    oldpathname=get(H.LoadBtn,'userdata');
                    [fname,pathname]=uigetfile([oldpathname '*.mat'],'Load Material Database');
                    if fname ~= 0
                        set(H.LoadBtn,'userdata',pathname);
                        load([pathname fname],'MatLib');
                        FigHandle=obj.iMatableF;
                        obj.DelMatl([1:obj.NumMat]);
                        for I=1:MatLib.NumMat
                            obj.AddMatl(MatLib.GetMatNum(I));
                        end
                        delete(MatLib);
                        obj.iMatableF=FigHandle;
                        obj.iSource=[pathname fname];
                        obj.ShowTable('PopulateTable')
                        %MatLib=ConvertOldMatLib(MatLib);
                        %MatDbase=PopulateMatDbase(handles.MatTable, MatLib);
                        %set(handles.MatTable,'Data',MatDbase);
                    end
                case 'cancel'
                    handle=varargin{1};
                    H=get(get(handle,'parent'),'user');
                    YES='Yes';
                    Response=questdlg('Are you sure want to discard all changes?','Confirm',YES,'No','No');
                    if strcmpi(Response,YES)
                        OrigMatLib=getappdata(obj.iMatableF,'OrigMatLib');
                        if obj.NumMat>0
                            obj.DelMatl([1:obj.NumMat]);
                        end
                        for I=1:OrigMatLib.NumMat
                            obj.AddMatl(OrigMatLib.GetMatNum(I))
                        end
                        obj.iSource=OrigMatLib.iSource;
                        obj.ShowTable('ok',handle,[]);
                        obj.GUIModFlag=false;
                    end
                case 'insertrow'
                    handle=varargin{1};
                    H=get(get(handle,'parent'),'user');
                    obj.DefineNewMaterial('init');
                    uiwait(obj.iNewMatF)
                    obj.iSource=[obj.iSource '*']
                    obj.ShowTable('PopulateTable')
                    obj.GUIModFlag=true;
                case 'save'
                    handle=varargin{1};
                    H=get(get(handle,'parent'),'user');
                    oldpathname=get(H.LoadBtn,'userdata');
                    [fname,pathname]=uiputfile([oldpathname '*.mat'],'Save Material Database');
                    if fname ~= 0
                        set(H.LoadBtn,'userdata',pathname);
                        MatLib=obj;
                        FigHandle=MatLib.iMatableF;
                        MatLib.iMatableF=[];
                        %MatDbase=get(handles.MatTable,'Data');  
                        README={'"MatLib" has been converted to an object to enable new material models.'; ...
                                '"PPMat" is the base class for materials.  PPMatLib is the library class.'};
                        save([pathname fname],'MatLib','README');
                        obj.iSource=[pathname fname];
                        MatLib.iMatableF=FigHandle;
                        obj.ShowTable('PopulateTable')
                    end
                case 'sortrow'
                    handle=varargin{1};
                    H=get(get(handle,'parent'),'user');
                    SortCol=get(H.FieldList,'value');
                    Data=get(H.Table,'data');
                    ColData=Data(:,SortCol+1);
                    try
                        [NewCol, Index]=sort(ColData);
                    catch ME
                        %ME.getReport
                        try
                            NewCol=cell2mat(ColData);
                            if length(NewCol)~=length(ColData)
                                for I=1:length(ColData)
                                    if isempty(ColData{I})
                                        ColData{I}=0;
                                    end
                                end
                                NewCol=cell2mat(ColData);
                            end
                            [NewCol, Index]=sort(NewCol);
                            obj.GUIModFlag=true;
                        catch ME
                            %ME.getReport
                            Index=[1:obj.NumMat];
                            obj.AddError('Sort could not be completed.')
                        end
                    end
                    obj.iMatObjList=obj.iMatObjList(Index);
                    obj.UpdateInternalVars;
                    obj.iSource=[obj.iSource '*'];
                    obj.ShowTable('PopulateTable');
                case 'deleterow'
                    handle=varargin{1};
                    H=get(get(handle,'parent'),'user');
                    GUIColNames=get(H.Table,'columnname');
                    DelCol=find(strcmpi(GUIColNames,'Del'));
                    NameCol=find(strcmpi(GUIColNames,'Name'));
                    Table=get(H.Table,'data');
                    ColsToDel=find(cell2mat(Table(:,DelCol)));
                    YES='Yes';
                    Response=questdlg('Are you sure want to delete all checked materials?','Confirm',YES,'No','No');
                    if strcmpi(Response,YES)
                    %     for i=IBCs'
                    %         MatDbase(i,:)=MatDbase(end,:);
                    %     end
                        obj.iSource=[obj.iSource '*']
                        obj.DelMatl(ColsToDel);
                        obj.ShowTable('PopulateTable')
                        obj.GUIModFlag=true;
                    end
                otherwise
                    obj.AddError(sprintf('Unknown action for ShowTable function "%s"',Action))
                obj.ShowErrorText;
            end
            
        end
        function Success=DelMatl(obj, Mat2Del)
            if ischar(Mat2Del)
                MatNum=find(strcmpi(obj.iNameList,Mat2Del));
            elseif iscell(Mat2Del)
                for I=1:length(Mat2Del)
                    if ischar(Mat2Del{I})
                        MatNum(I)=find(strcmpi(obj.iNameList,Mat2Del{I}));
                    else
                        MatNum(I)=Mat2Del{I};
                    end
                end
            elseif isnumeric(Mat2Del)
                MatNum=Mat2Del;
            end
            MatNum=sort(MatNum);
            MatNum=MatNum(end:-1:1);
            if ~isempty(MatNum) && max(MatNum) <= obj.NumMat
                for I=reshape(MatNum,1,[])
                    obj.iMatObjList=obj.iMatObjList([1:obj.NumMat]~=I);
                end
                obj.ClearProps;
                obj.UpdateInternalVars;
                Success=true;
                obj.GUIModFlag=true;
            else
                Success=false;
                obj.AddError(sprintf('Material number %.0f not found so can''t be be deleted.',max(MatNum)))
            end
        end
        function Success=ReplMatl(obj, Mat2Repl, NewMat)
            if ischar(Mat2Repl)
                MatNum=find(strcmpi(obj.iNameList,Mat2Repl));
            else
                MatNum=Mat2Repl;
            end
            OldMat=obj.GetMatNum(MatNum);
            if strcmpi(NewMat.Name, OldMat.Name) || isempty(find(strcmpi(NewMat.Name,obj.iNameList)))
                obj.iMatObjList{MatNum}=NewMat;
                %obj.iNameList(strcmpi(obj.iNameList,OldMat.Name))=NewMat.Name;
                obj.ClearProps;
                obj.UpdateInternalVars;
                Success=true;
                obj.GUIModFlag=true;
            else
                Success=false;
                obj.AddError(['Material name ' NewMat.Name ' already exists in library.'])
            end
        end
        
        function AddMatl(obj, PPMatObject)
            obj.AddError;
            if any(strcmpi(PPMatObject.Name, obj.iNameList))
                obj.AddError(sprintf('Material "%s" already exists in library (material names MUST be unique).',PPMatObject.Name))
            end
            if strcmpi(PPMatObject.Type,'abstract')
                obj.AddError(sprintf('Abstract materials cannot be added to the library. (%s)',PPMatObject.Name))
            end
            if isempty(obj.ErrorText)
                obj.iMatObjList{end+1}=PPMatObject;
                obj.ClearProps;
                obj.UpdateInternalVars;
                obj.GUIModFlag=true;
%                 obj.iMatTypeList{end+1}=PPMatObject.Type;
%                 obj.iMatTypeList=unique(obj.iMatTypeList);
%                 obj.iNameList{end+1}=PPMatObject.Name;
%                 obj.iParamList=unique([obj.iParamList; fields(PPMatObject)]);
%                 %Ensure Abstract fields are at the top
%                 AbstractFields=fields(PPMat);
%                 for I=1:length(AbstractFields)
%                     obj.iParamList=obj.iParamList(~strcmpi(obj.iParamList,AbstractFields(I)));
%                 end
%                 obj.iParamList=[AbstractFields; obj.iParamList];
            else
                obj.AddError('No material added.')
                obj.ShowErrorText;
            end 
        end
    end
end

function mustBeChar(Value)
    if ~isempty(Value) & ~ischar(Value)
        error('Value must be a character.')
    end
end
    