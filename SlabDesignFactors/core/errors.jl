struct NoValidSectionsError <: Exception
    msg::String
end

Base.showerror(io::IO, e::NoValidSectionsError) = print(io, e.msg)
