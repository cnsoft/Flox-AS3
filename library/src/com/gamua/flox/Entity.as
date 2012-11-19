package com.gamua.flox
{
    import com.gamua.flox.utils.DateUtil;
    import com.gamua.flox.utils.HttpMethod;
    import com.gamua.flox.utils.HttpStatus;
    import com.gamua.flox.utils.cloneObject;
    import com.gamua.flox.utils.createUID;
    import com.gamua.flox.utils.createURL;
    import com.gamua.flox.utils.describeType;
    import com.gamua.flox.utils.execute;
    
    import flash.net.registerClassAlias;
    import flash.system.Capabilities;
    import flash.utils.Dictionary;
    import flash.utils.getQualifiedClassName;
    
    public class Entity
    {
        private var mType:String;
        private var mID:String;
        private var mCreatedAt:Date;
        private var mUpdatedAt:Date;
        private var mOwnerID:String;
        private var mPermissions:Object;
        
        private static var sRegisteredTypes:Dictionary = new Dictionary();
        
        public function Entity(type:String)
        {
            if (Capabilities.isDebugger && 
                getQualifiedClassName(this) == "com.gamua.flox::Entity")
            {
                throw new Error("Abstract class -- do not instantiate");
            }
            
            if (type == null) 
                throw new ArgumentError("'type' must not be 'null'");
            
            mType = type;
            mID = createUID();
            mCreatedAt = new Date();
            mUpdatedAt = new Date();
            mOwnerID = Flox.localPlayer ? Flox.localPlayer.id : null; 
            mPermissions = {};
        }
        
        // onComplete(entity:Entity)
        // onError(error:String, transient:Boolean)
        public function save(onComplete:Function, onError:Function):void
        {
            var self:Entity = this;
            var path:String = createURL(mType, mID);
            
            Flox.service.request(HttpMethod.PUT, path, this.toObject(), 
                onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                execute(onComplete, self);
            }
            
            function onRequestError(error:String, httpStatus:int):void
            {
                execute(onError, error, HttpStatus.isTransientError(httpStatus));
            }
        }
        
        // onComplete(entity:Entity, fromCache:Boolean)
        // onError(error:String, transient:Boolean)
        public function refresh(onComplete:Function, onError:Function):void
        {
            var path:String = createURL(mType, mID);
            var self:Entity = this;
            
            Flox.service.request(HttpMethod.GET, path, null, onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                refreshEntity(self, body);
                execute(onComplete, self, httpStatus == HttpStatus.NOT_MODIFIED);
            }
            
            function onRequestError(error:String, httpStatus:int):void
            {
                execute(onError, error, HttpStatus.isTransientError(httpStatus));
            }
        }
        
        // onComplete(entity:Entity)
        // onError(error:String, transient:Boolean)
        public function destroy(onComplete:Function, onError:Function):void
        {
            var self:Entity = this;
            Entity.destroy(mType, mID, onDestroyComplete, onDestroyError);
            
            function onDestroyComplete():void
            {
                execute(onComplete, self);
            }
            
            function onDestroyError(error:String, httpStatus:int):void
            {
                execute(onError, error, HttpStatus.isTransientError(httpStatus));
            }
        }
        
        // static methods
        
        // onComplete(entity:Entity, fromCache:Boolean)
        // onError(error:String, transient:Boolean)
        public static function load(type:String, id:String, onComplete:Function, onError:Function):void
        {
            var entity:Entity;
            var path:String = createURL(type, id);
            
            Flox.service.request(HttpMethod.GET, path, null, onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                entity = Entity.fromObject(type, id, body);
                execute(onComplete, entity, httpStatus == HttpStatus.NOT_MODIFIED);
            }
            
            function onRequestError(error:String, httpStatus:int):void
            {
                // TODO - return cached entity in additional 'onError' parameter
                //entity = loadFromCache(type, id);
                //execute(onError, error, entity);
                
                execute(onError, error, HttpStatus.isTransientError(httpStatus));
            }
        }
        
        // onComplete()
        // onError(error:String, transient:Boolean)
        public static function destroy(type:String, id:String, 
                                       onComplete:Function, onError:Function):void
        {
            var path:String = createURL(type, id);
            Flox.service.request(HttpMethod.DELETE, path, null, onRequestComplete, onRequestError);
            
            function onRequestComplete(body:Object, httpStatus:int):void
            {
                // TODO: remove entity from cache
                execute(onComplete);
            }
            
            function onRequestError(error:String, httpStatus:int):void
            {
                execute(onError, error, HttpStatus.isTransientError(httpStatus));
            }
        }
        
        // helpers

        internal function toObject():Object
        {
            var object:Object = cloneObject(this);

            object["ownerId"] = mOwnerID;
            object["createdAt"] = DateUtil.toString(mCreatedAt);
            object["updatedAt"] = DateUtil.toString(mUpdatedAt);
            
            if ("authID" in object)
                object["authId"] = object["authID"];

            delete object["ownerID"];
            delete object["authID"];
            
            return object;
        }
        
        internal static function fromObject(type:String, id:String, data:Object):Entity
        {
            var entity:Entity;
            
            if (type in sRegisteredTypes)
                entity = new (sRegisteredTypes[type] as Class)();
            else
                throw new Error("Entity type not recognized: " + type);
            
            entity.id = id;
            refreshEntity(entity, data);
            
            return entity;
        }
        
        private static function refreshEntity(entity:Entity, data:Object):void
        {
            for each (var accessor:XML in describeType(entity).accessor)
            {
                var access:String = accessor.@access.toString();
                if (access == "readwrite") 
                    updateProperty(entity, data, accessor.@name.toString());
            }
        }
        
        private static function updateProperty(entity:Entity, serverData:Object, 
                                               propertyName:String):void
        {
            var clientPN:String = propertyName;
            var serverPN:String = propertyName;
            
            if      (propertyName == "ownerID") { clientPN = "ownerID"; serverPN = "ownerId"; }
            else if (propertyName == "authID")  { clientPN = "authID";  serverPN = "authId";  }
            
            if (serverPN in serverData)
            {
                if (propertyName == "createdAt" || propertyName == "updatedAt")
                    entity[clientPN] = DateUtil.parse(serverData[serverPN]);
                else
                    entity[clientPN] = serverData[serverPN];
            }
        }
        
        // properties
        
        public function get id():String { return mID; }
        public function set id(value:String):void { mID = value; }
        
        public function get type():String { return mType; }
        public function set type(value:String):void { mType = value; }
        
        public function get ownerID():String { return mOwnerID; }
        public function set ownerID(value:String):void { mOwnerID = value; }
        
        public function get permissions():Object { return mPermissions; }
        public function set permissions(value:Object):void { mPermissions = value ? value : {}; }
        
        public function get createdAt():Date { return mCreatedAt; }
        public function set createdAt(value:Date):void { mCreatedAt = value; }
        
        public function get updatedAt():Date { return mUpdatedAt; }
        public function set updatedAt(value:Date):void { mUpdatedAt = value; }
        
        // TODO
        // public function get isSaved():Boolean { return ???; }
        
        // type registration
        
        public static function register(entityType:String, entityClass:Class):void
        {
            if (entityType == null || entityClass == null)
                throw new ArgumentError("argument must not be null");
            
            sRegisteredTypes[entityType] = entityClass;
            registerClassAlias(entityType, entityClass);
        }
    }
}