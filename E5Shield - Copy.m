classdef E5Shield < handle
    
    % This class defines an "E5Shield" object
    %
    % This code modified from "arduino" object
    % Giampiero Campa, Aug 2010, Copyright 2009 The MathWorks, Inc.
    
    properties (SetAccess=private,GetAccess=private)
        aser   % Serial Connection
        pins   % Pin Status Vector
    end
    
    properties (Hidden=true)
        chkp = true;   % Checks parameters before every operation
    end
    
    methods
        
        % constructor, connects to the board and creates an E5Shield object
        function a=E5Shield(comPort)
            % check nargin and port
            if (nargin<1) | (~ischar(comPort)),
                s = ['There must be one input argument. e.g., '];
                s = [s 'E5Shield(''COM8''), where ''COM8'' is the \n'];
                s = [s 'serial port to which the Arduino is connected.\n'];
                s = [s,'For more info use: " >> explainError"'];
                error('MATLAB:E5NoArgs',s);
            end
            
            % check if we are already connected or if
            %  serial port is currently used by MATLAB
            if (isa(a.aser,'serial') && isvalid(a.aser) ...
                    && strcmpi(get(a.aser,'Status'),'open')) | ...
                    (~isempty(instrfind({'Port'},{comPort}))),
                s = ['Port ' comPort ' already used by MATLAB. '];
                s = [s 'This connection must be deleted.\n'];
                s = [s 'For more info use: " >> explainError"'];
                error('MATLAB:E5PortAlreadyUsed',s);
            end
            
            % define serial object
            a.aser=serial(comPort,'BaudRate',115200);
            
            % open port
            try
                fopen(a.aser);
            catch ME,
                disp(ME.message)
                delete(a);
                s = ['Could not open port: ' comPort '\n'];
                s = [s 'For more info use: " >> explainError"'];
                error('MATLAB:E5OpenPort',...
                    ['Could not open port: ' comPort]);
            end
            
            % it takes several seconds to connect
            fprintf('Attempting connection: 3');
            for i=1:3,
                pause(0.5); fprintf(',');
                pause(0.5); fprintf('%1d',3-i);
            end
            fprintf('\n');
            
            % query script type
            fwrite(a.aser,['??'],'uchar');
            chk=fscanf(a.aser,'%d');
            
            % exit if there was no answer
            if isempty(chk)
                delete(a);
                s = 'Connection unsuccessful.  ';
                s = [s 'For more info enter ">> explainError"'];
                error('MATLAB:E5ConnectUnsuccessful',s)
            end
            
            % check returned value
            if chk==1,
                disp('E5Shield Script detected!');
            else
                delete(a);
                s = 'Unknown Script.  ';
                s = [s 'For more info enter ">> explainError"'];
                error('MATLAB:E5UnknownScript',s);
            end
            
            a.aser.Tag='ok';        % set a.aser tag
            % initialize pin vector (-1 is unassigned, 0 is input, 1 is output)
            a.pins=-1*ones(1,13);
            % initialize servo vector (-1 is unknown, 0 is detached, 1 is attached)
            disp('E5Shield successfully connected!');
        end % E5Shield
        
        % distructor, deletes the object
        function delete(a)
            % if it is a serial, valid and open then close it
            if isa(a.aser,'serial') && isvalid(a.aser) && strcmpi(get(a.aser,'Status'),'open'),
                if ~isempty(a.aser.Tag),
                    try
                        % trying to leave it in a known unharmful state
                        for i=2:13,
                            a.pinMode(i,'output');
                            a.digitalWrite(i,0);
                            a.pinMode(i,'input');
                        end
                    catch ME
                        % disp but proceed anyway
                        disp(ME.message);
                        disp('Proceeding to deletion anyway');
                    end
                end
                fclose(a.aser);
            end
            
            % if it's an object delete it
            if isobject(a.aser),
                delete(a.aser);
            end
        end % delete
        
        % disp, displays the object
        function disp(a) % display
            if isvalid(a),
                if isa(a.aser,'serial') && isvalid(a.aser),
                    disp(['<a href="matlab:help E5Shield">E5Shield</a> object connected to ' a.aser.port ' port']);
                    disp('E5Shield Server running on the E5Shield board');
                    disp(' ');
                    a.pinMode
                    disp(' ');
                else
                    disp('<a href="matlab:help E5Shield">E5Shield</a> object connected to an invalid serial port');
                    disp('Please delete the E5Shield object');
                    disp(' ');
                end
            else
                disp('Invalid <a href="matlab:help E5Shield">E5Shield</a> object');
                disp('Please clear the object and instantiate another one');
                disp(' ');
            end
        end
        
        % pin mode, changes pin mode
        function pinMode(a,pin,str)
            % a.pinMode(pin,str); specifies the pin mode of a digital pin.
            % The first argument before the function name, a, is the E5Shield object.
            % The first argument, pin, is the number of the digital pin (2 to 13).
            % The second argument, str, is a string that can be 'input' or 'output',
            % Called with one argument, as a.pin(pin) it returns the mode of
            % the digital pin, called without arguments, prints the mode of all the
            % digital pins. Note that the digital pins from 0 to 13 are located on
            % the upper right part of the board, while the analog pins from
            % 0 to 5 are located in the lower right corner of the board.
            %
            % Examples:
            % a.pinMode(11,'output') % sets digital pin #11 as output
            % a.pinMode(10,'input')  % sets digital pin #10 as input
            % a.pinMode(5)           % prints the status of digital pin #5
            % a.pinMode              % prints the status of all pins
            %
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % check arguments if a.chkp is true
            if a.chkp,
                % check nargin
                if nargin>3,
                    error('MATLAB:E5PinModeArgs',...
                        ['This function cannot have more than 3'...
                        ' arguments, object, pin and str']);
                end
                % if pin argument is there check it
                if nargin>1,
                    errstr=E5Shield.checknum(pin,'pin number',2:13);
                    if ~isempty(errstr),
                        error('MATLAB:E5PinModePin',errstr);
                    end
                end
                % if str argument is there check it
                if nargin>2,
                    errstr=E5Shield.checkstr(str,'pin mode',{'input','output'});
                    if ~isempty(errstr),
                        error('MATLAB:E5PinModeIO',errstr);
                    end
                end
            end
            % perform the requested action
            if nargin == 3,
                
                %%%%%%%%%%%%%%%%%%%%%%%%% CHANGE PIN MODE %%%%%%%%%%%%%%%%%
                % assign value
                if lower(str(1))=='o', val=1; else val=0; end
                % do the actual action here
                
                % send mode, pin and value
                fwrite(a.aser,['P' '0'+pin '0'+val],'uchar');
                % store 0 for input and 1 for output
                a.pins(pin)=val;
                
            elseif nargin==2,
                % print pin mode for the requested pin
                mode={'UNASSIGNED','set as INPUT','set as OUTPUT'};
                disp(['Digital Pin ' num2str(pin) ' is currently ' mode{2+a.pins(pin)}]);
                
            else
                % print pin mode for each pin
                mode={'UNASSIGNED','set as INPUT','set as OUTPUT'};
                for i=2:13;
                    disp(['Digital Pin ' num2str(i,'%02d') ' is currently ' mode{2+a.pins(i)}]);
                end
                
            end
        end % pinmode
        
        % digital read
        function val=digitalRead(a,pin)
            % val=a.digitalRead(pin); performs digital input on a given E5Shield pin.
            % The first argument before the function name, a, is the E5Shield object.
            % The argument pin, is the number of the digital pin (2 to 13)
            % where the digital input needs to be performed. Note that the digital pins
            % from 2 to 13 are located on the upper right part of the
            % board.
            %
            % Example:
            % val=a.digitalRead(4); % reads pin #4 and stores value
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%
            % check arguments if a.chkp is true
            if a.chkp,
                % check nargin
                if nargin~=2,
                    error('Function must have the "pin" argument');
                end
                % check pin
                errstr=E5Shield.checknum(pin,'pin number',2:13);
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% PERFORM DIGITAL INPUT %%%%%%%%%%%%%%%
            % send mode and pin
            fwrite(a.aser,['d' '0'+pin],'uchar');
            % get value
            val=fscanf(a.aser,'%d');
        end % digitalread
        
        % digital write
        function digitalWrite(a,pin,st)
            % a.digitalWrite(pin,st); performs digital output on a given pin.
            % The first argument before the function name, a, is the E5Shield object.
            % The second argument, pin, is the number of the digital pin (2 to 13)
            % where the digital output needs to be performed.
            % The third argument, st, is the state (either 0 or 1) for the output
            % Note that the digital pins from 0 to 13 are located on the upper right part
            % of the board.
            %
            % Examples:
            % a.digitalWrite(13,1); % sets pin #13 high
            % a.digitalWrite(13,0); % sets pin #13 low
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%
            % check arguments if a.chkp is true
            if a.chkp,
                % check nargin
                if nargin~=3,
                    s='Function must have the "pin" and "st" arguments, ';
                    s=[s 'e.g., digitalWrite(13,1); % pin=13, state=1.'];
                    error(s);
                end
                
                % check pin
                errstr=E5Shield.checknum(pin,'pin number',2:13);
                if ~isempty(errstr), error(errstr); end
                % check st
                errstr=E5Shield.checknum(st,'state',0:1);
                if ~isempty(errstr), error(errstr); end
                % get object name
                if isempty(inputname(1)), name='object'; else name=inputname(1); end
                % pin should be configured as output
                if a.pins(pin)~=1,
                    warning('MATLAB:E5Shield:digitalWrite',['If digital pin ' num2str(pin) ' is set as input, digital output takes place only after using ' name' '.pinMode(' num2str(pin) ',''output''); ']);
                end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% PERFORM DIGITAL OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%
            % send mode, pin and state
            fwrite(a.aser,['D' '0'+pin '0'+st],'uchar');
        end % digitalwrite
        
        % analog read
        function val=analogRead(a,pin)
            % val=a.analogRead(pin); Performs analog input on a given E5Shield pin.
            % The first argument before the function name, a, is the E5Shield object.
            % The second argument, pin, is the number of the analog input pin (0 to 3)
            % where the analog input needs to be performed. The
            % returned value, val, ranges from 0 to 1023, with 0 corresponding to an
            % input voltage of 0 volts, and 1023 to a reference value that is
            % typically 5 volts (this voltage can be set up by the analogReference
            % function). Therefore, assuming a range from 0 to 5 V the resolution is
            % .0049 volts (4.9 mV) per unit.
            % Note that the analog input pins 0 to 3 are located on the lower right
            % corner of the board.
            %
            % Example:
            % val=a.analogRead(0); % reads analog input pin # 0
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%
            % check arguments if a.chkp is true
            if a.chkp,
                % check nargin
                if nargin~=2,
                    error('Function must have the "pin" argument');
                end
                % check pin
                errstr=E5Shield.checknum(pin,'analog input pin number',0:11);
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% PERFORM ANALOG INPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % send mode and pin
            fwrite(a.aser,['a' '0'+pin],'uchar');
            % get value
            val=fscanf(a.aser,'%d');
        end % analogread
        
        % function analog write
        function analogWrite(a,pin,val)
            % a.analogWrite(pin,val); Performs analog output on a given E5Shield pin.
            % The first argument before the function name, a, is the E5Shield object.
            % The first argument, pin, is the number of the DIGITAL pin where the analog
            % (PWM) output needs to be performed. Allowed pins for AO are 3,5,6,9,10,11
            % The second argument, val, is the value from 0 to 255 for the level of
            % analog output. Note that the digital pins from 2 to 13 are located on the
            % upper right part of the board.
            %
            % Examples:
            % a.analogWrite(11,90); % sets pin #11 to 90/255
            % a.analogWrite(3,10); % sets pin #3 to 10/255
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%
            % check arguments if a.chkp is true
            if a.chkp,
                % check nargin
                if nargin~=3,
                    error('Function must have the "pin" and "val" arguments');
                end
                % check pin
                errstr=E5Shield.checknum(pin,'pwm pin number',[3 5 6 9 10 11]);
                if ~isempty(errstr), error(errstr); end
                % check val
                errstr=E5Shield.checknum(val,'analog output level',0:255);
                if ~isempty(errstr), error(errstr); end
                % get object name
                if isempty(inputname(1)), name='object'; else name=inputname(1); end
                % pin should be configured as output
                if a.pins(pin)~=1,
                    warning('MATLAB:E5Shield:analogWrite',['If digital pin ' num2str(pin) ' is set as input, pwm output takes place only after using ' name '.pinMode(' num2str(pin) ',''output''); ']);
                end
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%% PERFORM ANALOG OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%%
            % send mode, pin and value
            fwrite(a.aser,['A' '0'+pin val],'uchar');
        end % analogwrite
        
        
        % function analog reference
        function analogReference(a,str)
            % a.analogReference(str); Changes voltage reference on analog input pins
            % The first argument before the function name, a, is the E5Shield object.
            % The second argument, str, is one of these strings: 'default', 'internal'
            % or 'external'. This sets the reference voltage used at the top of the
            % input ranges.
            %
            % Examples:
            % a.analogReference('default'); % sets default reference
            % a.analogReference('internal'); % sets internal reference
            % a.analogReference('external'); % sets external reference
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%
            % check arguments if a.chkp is true
            if a.chkp,
                % check nargin
                if nargin~=2,
                    error('Function must have the "reference" argument');
                end
                % check val
                errstr=E5Shield.checkstr(str,'reference',{'default','internal','external'});
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%% CHANGE ANALOG INPUT REFERENCE %%%%%%%%%%%
            if lower(str(1))=='e', ref='E';
            elseif lower(str(1))=='i', ref='I';
            else ref='D';
            end
            
            % send mode, pin and value
            fwrite(a.aser,['R' ref],'uchar');
        end % analogreference
        
        function servoWrite(a,n,val)
            % a.servoWrite(n,val); specifies the pulse width for a Servo motor.
            % The first argument before the function name, a, is the E5Shield object.
            % The second argument, n, is the Servo that will be adjusted.
            % The third argument, val, is the desired pulse width.
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%
            % check arguments if a.chkp is true
            if a.chkp
                % check nargin
                if nargin~=3,
                    error('Function must have the "n" (Servo number) and "val" arguments');
                end
                % check Servo number, n
                N=length(n);
                for i=1:N
                    num=n(i);
                    errstr=E5Shield.checknum(num,'Servo number',0:7);
                    if ~isempty(errstr), error(errstr); end
                end
                % check val
                V=length(val);
                for i=1:V
                    value=val(i);
                    errstr=E5Shield.checknum(value,'value',0:250);
                    if ~isempty(errstr), error(errstr); end
                end
            end
            
            %%%%%%%%%%%%%%%%%%%%% PERFORM SERVO OUTPUT %%%%%%%%%%%%%%%%%%
            % send mode, Servo number and value
            N=length(n);
            if isscalar(val),
                for i=1:N
                    fwrite(a.aser,['S' '0'+n(i) val],'uchar');
                end
                if N==length(val),
				               for i=1:N
                    fwrite(a.aser,['S' '0'+n(i) val(i)],'uchar');
                end
 else
                    s = 'In call to ServoWrite(n,val) the number of';
                    s = [s ' servos, "n", must be equal to the number'];
                    s = [s ' pulse widths, "val", (or val must be a'];
                    s = [s ' scalar).'];
                    error('MATLAB:E5ServoOutput',s);
                end
            end
        end % servoWrite
        
        function servoDisable(a,n)
            % a.servoDisable(n); disables a Servo motor by setting its pulse width out of range.
            % The first argument before the function name, a, is the E5Shield object.
            % The second argument, n, is the Servo to be disabled.
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%
            % check arguments if a.chkp is true
            if a.chkp
                % check nargin
                if nargin~=2,
                    error('Function must have the "n" (Servo number) argument');
                end
                % check Servo number, n
                errstr=E5Shield.checknum(n,'Servo number',0:7);
                if ~isempty(errstr), error(errstr); end
            end
            
            %%%%%%%%%%%%%%%%%%%%% PERFORM SERVO DISABLE %%%%%%%%%%%%%%%%%%
            % Given Servo is disabled by setting its value to 251.
            fwrite(a.aser,['S' '0'+n 251],'uchar');
        end %servoDisable
        
        function nunch=nunchuck(a)
            % a.nunchuck; stores and prints an array of values
            % containing: the joystick's x- and y-values; the x-, y- and
            % z-values of the accelerometer; whether or not the C- and
            % Z-buttons are being pressed.
            % The argument before the function name, a, is the E5Shield
            % object.
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%
            if a.chkp
                % check nargin
                if nargin~=1,
                    error('Function must be entered in the format a.nunchuck');
                end
            end
            %%%%%%%%%%%%%%%%%% PERFORM NUNCHUCK INPUT %%%%%%%%%%%%%%%%%%%%%
            % send mode
            fwrite(a.aser,['n',1],'uchar');
            % get values
            nunchVals = fscanf(a.aser,'%d');  % First read can give bad readings
            fwrite(a.aser,['n',1],'uchar');
            nunchVals = fscanf(a.aser,'%d');  % so read again.
            %pause(.1);
            % store values in a structure for readability
            nunch = struct('JoystickX',nunchVals(1),...
                'JoystickY',nunchVals(2),'AccelX',nunchVals(3),...
                'AccelY',nunchVals(4),'AccelZ',nunchVals(5),...
                'CButton',nunchVals(6),'ZButton',nunchVals(7));
        end %nunchuck
        
        function statLED(a,val)
            % a.statLED(val); determines the state of the status LED on the
            % E5Shield board.
            % If the argument is zero, the LED is turned off.  Any non-zero
            % value will turn the LED on.
            
            %%%%%%%%%%%%%%%%%%%%%%%%% ARGUMENT CHECKING %%%%%%%%%%%%%%%%%%%
            if a.chkp
                % check nargin
                if nargin~=2,
                    error('Function must have the "val" argument');
                end
                % check LED value, val
                errstr=E5Shield.checknum(val,'LED value',0:250);
                if ~isempty(errstr), error(errstr); end
            end
            %%%%%%%%%%%%%%%%%% PERFORM STATLED INPUT %%%%%%%%%%%%%%%%%%%%%
            if val==0
                fwrite(a.aser,['S' '0'+8 val],'uchar');
            else
                fwrite(a.aser,['S' '0'+8 251],'uchar');
            end
        end %statLED
    end % methods
    
    methods (Static) % static methods
        
        function errstr=checknum(num,description,allowed)
            % errstr=E5Shield.checknum(num,description,allowed); Checks numeric argument.
            % This function checks the first argument, num, described in the string
            % given as a second argument, to make sure that it is real, scalar,
            % and that it is equal to one of the entries of the vector of allowed
            % values given as a third argument. If the check is successful then the
            % returned argument is empty, otherwise it is a string specifying
            % the type of error.
            
            errstr=[];              % initialize error string
            if ~isnumeric(num),     % check num for type
                errstr=['The ' description ' must be numeric'];
                return
            elseif numel(num)~=1,  % check num for size
                errstr=['The ' description ' must be a scalar'];
                return
            elseif ~isreal(num),        % check num for realness
                errstr=['The ' description ' must be a real value'];
                return
            end
            
            % check num against allowed values
            if ~any(allowed==num),
                % form right error string
                if numel(allowed)==1,
                    errstr=['Unallowed value for ' description ', it must be exactly ' num2str(allowed(1))];
                elseif numel(allowed)==2,
                    errstr=['Unallowed value for ' description ', it must be either ' num2str(allowed(1)) ' or ' num2str(allowed(2))];
                elseif max(diff(allowed))==1,
                    errstr=['Unallowed value for ' description ', it must be an integer from ' num2str(allowed(1)) ' to ' num2str(allowed(end))];
                else
                    errstr=['Unallowed value for ' description ', it must be one of the following: ' mat2str(allowed)];
                end
            end
        end % checknum
        
        function errstr=checkstr(str,description,allowed)
            % errstr=E5Shield.checkstr(str,description,allowed); Checks string argument.
            % This function checks the first argument, str, described in the string
            % given as a second argument, to make sure that it is a string, and that
            % its first character is equal to one of the entries in the cell of
            % allowed characters given as a third argument. If the check is successful
            % then the returned argument is empty, otherwise it is a string specifying
            % the type of error.
            
            errstr=[];              % initialize error string
            if ~ischar(str),        % check string for type
                errstr=['The ' description ' argument must be a string'];
                return
            elseif numel(str)<1,    % check string for size
                errstr=['The ' description ' argument cannot be empty'];
                return
            end
            
            % check str against allowed values
            if ~any(strcmpi(str,allowed)),
                % make sure this is a hozizontal vector
                allowed=allowed(:)';
                % add a comma at the end of each value
                for i=1:length(allowed)-1,
                    allowed{i}=['''' allowed{i} ''', '];
                end
                % form error string
                errstr=['Unallowed value for ' description ', the value must be either: ' allowed{1:end-1} 'or ''' allowed{end} ''''];
                return
            end
        end % checkstr
        
        function errstr=checkser(ser,chk)
            % errstr=E5Shield.checkser(ser,chk); Checks serial connection argument.
            % This function checks the first argument, ser, to make sure that either:
            % 1) it is a valid serial connection (if the second argument is 'valid')
            % 3) it is open (if the second argument is 'open')
            % If the check is successful then the returned argument is empty,
            % otherwise it is a string specifying the type of error.
            
            errstr=[];                  % initialize error string
            switch lower(chk),          % check serial connection
                case 'valid',
                    if ~isvalid(ser),   % make sure is valid
                        disp('Serial connection invalid, please recreate the object to reconnect to a serial port.');
                        errstr='Serial connection invalid';
                        return
                    end
                case 'open',            % check openness
                    if ~strcmpi(get(ser,'Status'),'open'),
                        disp('Serial connection not opened, please recreate the object to reconnect to a serial port.');
                        errstr='Serial connection not opened';
                        return
                    end
                otherwise               % complain
                    error('second argument must be either ''valid'' or ''open''');
            end
        end % chackser
    end % static methods
    
end % class def