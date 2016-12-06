<cfcomponent output="false">

    <cffunction name="init" access="public" output="false">
        <cfscript>
            this.version = "1.1.7,1.1.8,1.4.5,2.0";
        </cfscript>
        <cfreturn this />
    </cffunction>

  <cffunction name="internalRedirect" access="public" output="false" returntype="void">
    <cfargument name="route" type="string" required="false" default="" />
    <cfargument name="controller" type="string" required="false" default="" />
    <cfargument name="action" type="string" required="false" default="" />
    <cfargument name="key" type="string" required="false" default="" />
    <cfargument name="params" type="string" required="false" default="" />
    <cfargument name="message" type="string" required="false" default="" />
    <cfscript>
      var loc = { args = Duplicate(arguments) };

      // setup the message in the params if one was passed in
      if (Len(arguments.message))
        url.message = arguments.message;
      StructDelete(arguments, "message");

      for (loc.item in loc.args)
        if (!isSimpleValue(loc.args[loc.item]))
          StructDelete(loc.args, loc.item, false);

      loc.url = ReplaceList(URLFor(argumentCollection=loc.args), "/index.cfm,/rewrite.cfm", "");

      if (!StructKeyExists(request, "wheels") or !StructKeyExists(request.wheels, "params"))
        request.wheels.params = {};

      if (StructKeyExists(request, "internalRedirect"))
        $throw(message="Multiple redirects happening. Fix your code!");

      request.internalRedirect = Duplicate(request.wheels.params);
      request.cgi.path_info = loc.url;
      loc.deleteItems = [ "action", "controller", "route", "format" ];

      for (loc.item in loc.deleteItems)
      {
        StructDelete(url , loc.item, false);
        StructDelete(form, loc.item, false);
      }

      this.setResponse(application.wheels.dispatch.$request());
    </cfscript>
    <cfreturn />
  </cffunction>

  <cffunction name="renderWithError" access="public" output="false" returntype="any">
    <cfargument name="error" type="string" required="true" />
    <cfargument name="message" type="string" required="false" default="" />
    <cfargument name="output" type="boolean" required="false" default="false" />
    <cfset arguments.route = arguments.error />
    <cfset structDelete(arguments, "error", false) />
    <cfset internalRedirect(argumentCollection=arguments) />
    <cfif arguments.output>
      <cfreturn this.response() />
    </cfif>
  </cffunction>

  <cffunction name="sendExceptionEmail" returntype="void" access="public" output="false" mixin="application,dispatch">
    <cfargument name="exception" type="any" required="true">
    <cfargument name="eventName" type="any" required="true">
    <cfscript>
      var loc = {};
      if (application.wheels.sendEmailOnError)
      {
        loc.mailArgs = {};
        $args(name="sendEmail", args=arguments);
        if (StructKeyExists(application.wheels, "errorEmailServer") && Len(application.wheels.errorEmailServer))
          loc.mailArgs.server = application.wheels.errorEmailServer;
        loc.mailArgs.from = application.wheels.errorEmailAddress;
        loc.mailArgs.to = application.wheels.errorEmailAddress;
        loc.mailArgs.subject = application.wheels.errorEmailSubject;
        loc.mailArgs.type = "html";
        loc.mailArgs.tagContent = $includeAndReturnOutput($template="wheels/events/onerror/cfmlerror.cfm", exception=arguments.exception);
        StructDelete(loc.mailArgs, "layouts", false);
        StructDelete(loc.mailArgs, "detectMultiPart", false);
        $mail(argumentCollection=loc.mailArgs);
      }
    </cfscript>
  </cffunction>

  <cffunction name="$runOnError" returntype="string" access="public" output="false" mixin="application,dispatch">
    <cfargument name="exception" type="any" required="true">
    <cfargument name="eventName" type="any" required="true">
    <cfscript>
      var loc = {};

      if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "initialized"))
      {
        if (application.wheels.showErrorInformation)
        {
          if (StructKeyExists(arguments.exception, "rootCause") && Left(arguments.exception.rootCause.type, 6) == "Wheels")
            loc.wheelsError = arguments.exception.rootCause;
          else if (StructKeyExists(arguments.exception, "cause") && StructKeyExists(arguments.exception.cause, "rootCause") && Left(arguments.exception.cause.rootCause.type, 6) == "Wheels")
            loc.wheelsError = arguments.exception.cause.rootCause;
          if (StructKeyExists(loc, "wheelsError"))
          {
            loc.returnValue = $includeAndReturnOutput($template="wheels/styles/header.cfm");
            loc.returnValue = loc.returnValue & $includeAndReturnOutput($template="wheels/events/onerror/wheelserror.cfm", wheelsError=loc.wheelsError);
            loc.returnValue = loc.returnValue & $includeAndReturnOutput($template="wheels/styles/footer.cfm");
          }
          else
          {
            $throw(object=arguments.exception);
          }
        }
        else
        {
          loc.returnValue = $includeAndReturnOutput($template="#application.wheels.eventPath#/onerror.cfm", exception=arguments.exception, eventName=arguments.eventName);
        }
      }
      else
      {
        $throw(object=arguments.exception);
      }
    </cfscript>
    <cfreturn loc.returnValue>
  </cffunction>

</cfcomponent>
