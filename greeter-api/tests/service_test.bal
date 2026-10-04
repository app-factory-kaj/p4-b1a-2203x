import ballerina/http;
import ballerina/test;

final http:Client testClient = check new ("http://localhost:9090");

@test:Config {}
function testGreetingWithoutName() returns error? {
    Greeting greeting = check testClient->get("/greeting");
    test:assertEquals(greeting.message, "Hello, World!");
    test:assertTrue(greeting?.name is (), "expected no name to be echoed back");
}

@test:Config {}
function testGreetingWithName() returns error? {
    Greeting greeting = check testClient->get("/greeting?name=Ada");
    test:assertEquals(greeting.message, "Hello, Ada!");
    test:assertEquals(greeting?.name, "Ada");
}

@test:Config {}
function testGreetingWithBlankName() returns error? {
    http:Response response = check testClient->get("/greeting?name=%20");
    test:assertEquals(response.statusCode, 400);
}
