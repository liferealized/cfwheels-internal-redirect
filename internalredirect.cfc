<cfcomponent mixin="application,controller,dispatch" output="false">

    <cffunction name="init" access="public" output="false">
        <cfscript>
            this.version = "1.1.7,1.1.8";   
        </cfscript>
        <cfreturn this />
    </cffunction>

  <cffunction name="internalRedirect" access="private" output="false" returntype="void">
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

  <cffunction name="renderWithError" access="private" output="false" returntype="void">
    <cfargument name="error" type="string" required="true" />
    <cfargument name="message" type="string" required="false" default="" />
    <cfset arguments.route = arguments.error />
    <cfset structDelete(arguments, "error", false) />
    <cfreturn internalRedirect(argumentCollection=arguments) />
  </cffunction>
    
</cfcomponent>