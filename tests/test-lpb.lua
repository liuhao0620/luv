local lpb = require("pb")
local lpbio = require("pb.io")
local lpbconv = require("pb.conv")
local lpbbuffer = require("pb.buffer")
local lpbslice = require("pb.slice")
local protoc = require("lib/protoc")

return require('lib/tap')(function (test)
    test("basic pb test", function (print, p, expect, uv)
        protoc:load([[
            syntax="proto3"
            package PB;
            enum Sex
            {
                Male = 1;
                Female = 2;
                Unkown = 3;
            }

            message Friend
            {
                string name = 1;
                int64 phone = 2;
            }

            message Person
            {
                string id = 1;
                string name = 2;
                int32 age = 3;
                Sex sex = 4;
                int64 phone = 5;
                repeated Friend friends = 6;
            }
        ]])

        local person = {
            id = "xxxxxxxxxxxxxxxxxx",
            name = "xxxxxx",
            age = 24,
            sex = "Male",
            phone = 13245678910,
            friends = {
                {name = "arenold", phone = 12345678910},
                {name = "bernard", phone = 10987654321}
            }
        }

        local bytes = assert(lpb.encode("PB.Person", person))        
        p(lpb.tohex(bytes))
        local decode_person = assert(lpb.decode("PB.Person", bytes))
        p(decode_person)
    end)
end)
