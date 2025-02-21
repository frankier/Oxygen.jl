module AppContext
import Base: @kwdef, wait, close, isopen
import Base.Threads: ReentrantLock
using HTTP
using HTTP: Server, Router
using ..Types

export ServerContext, CronContext, TasksContext, Documenation, EagerReviseService, Service, history, wait, close, isopen

function defaultSchema() :: Dict
    Dict(
        "openapi" => "3.0.0",
        "info" => Dict(
            "title" => "API Overview",
            "version" => "1.0.0"
        ),
        "paths" => Dict()
    )
end

@kwdef struct CronContext
    run             :: Ref{Bool}                = Ref{Bool}(false)  # Flag used to stop all running jobs
    active_jobs     :: Set{ActiveCron}          = Set()   # Set of all running tasks
    registered_jobs :: Set{RegisteredCron}      = Set()   # Set of cron expressions and functions (expression, name, function)
    job_definitions :: Set{CronDefinition}      = Set()   # Cron job definitions registered through the router() (path, httpmethod, cron_expression)
end

@kwdef struct TasksContext
    active_tasks        :: Set{ActiveTask}          = Set() # Set of all running tasks which contains (task_id, timer)
    registered_tasks    :: Set{RegisteredTask}      = Set() # Vector of repeat task definitions (path, httpmethod, interval)
    task_definitions    :: Set{TaskDefinition}      = Set() # Set of all registered task definitions ()
end

@kwdef struct Documenation
    enabled         :: Ref{Bool}                    = Ref{Bool}(true)
    router          :: Ref{Nullable{Router}}        = Ref{Nullable{Router}}(nothing)    # used for docs & metrics internal endpoints
    docspath        :: Ref{String}                  = Ref{String}("/docs")
    schemapath      :: Ref{String}                  = Ref{String}("/schema")
    schema          :: Dict                         = defaultSchema()
    taggedroutes    :: Dict{String, TaggedRoute}    = Dict{String, TaggedRoute}()       # used to group routes by tag
end

@kwdef struct EagerReviseService
    task::Task
    done::Ref{Bool}
end

function Base.close(revise_service::EagerReviseService)
    revise_service.done[] = true
end

@kwdef struct Service
    server              :: Ref{Nullable{Server}}    = Ref{Nullable{Server}}(nothing)
    router              :: Router                   = Router()
    custommiddleware    :: Dict{String, Tuple}      = Dict{String, Tuple}()
    middleware_cache    :: Dict{String, Function}   = Dict{String, Function}()
    history             :: History                  = History(1_000_000)
    history_lock        :: ReentrantLock            = ReentrantLock()
    external_url        :: Ref{Nullable{String}}    = Ref{Nullable{String}}(nothing)
    eager_revise        :: Ref{Nullable{EagerReviseService}} = Ref{Nullable{EagerReviseService}}(nothing)
    middleware_cache_lock :: ReentrantLock          = ReentrantLock()
end

@kwdef struct ServerContext
    service :: Service          = Service()    
    docs    :: Documenation     = Documenation()
    cron    :: CronContext      = CronContext()
    tasks   :: TasksContext     = TasksContext()
    mod     :: Nullable{Module} = nothing
    app_context :: Ref{Any}     = Ref{Any}(missing) # This stores a reference to an Context{T} object
end

Base.isopen(service::Service)   = !isnothing(service.server[]) && isopen(service.server[])
Base.wait(service::Service)     = !isnothing(service.server[]) && wait(service.server[])
function Base.close(service::Service)
    !isnothing(service.server[]) && close(service.server[])
    !isnothing(service.eager_revise[]) && close(service.eager_revise[])
end


# @eval begin
#     """
#         ServerContext(ctx::ServerContext; kwargs...)

#     Create a new `ServerContext` object by copying an existing one and optionally overriding some of its fields with keyword arguments.
#     """
#     function ServerContext(ctx::ServerContext; $([Expr(:kw ,k, :(ctx.$k)) for k in fieldnames(ServerContext)]...))
#         return ServerContext($(fieldnames(ServerContext)...))
#     end
# end

end
