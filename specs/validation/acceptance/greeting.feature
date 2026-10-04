Feature: Greeting

  @story-1
  Rule: Any caller can request a greeting and get a reply confirming the service is reachable

    Scenario: A caller requests a greeting with no name
      Given the greeter service is reachable
      When a Caller requests a greeting without supplying a name
      Then the Caller receives a generic hello greeting

  @story-2
  Rule: A caller who supplies a name receives a greeting personalized to that name

    Scenario: A caller requests a greeting with a name
      Given the greeter service is reachable
      When a Caller requests a greeting supplying the name "Ada"
      Then the Caller receives a greeting that addresses "Ada"

    Scenario: A caller omits the name
      Given the greeter service is reachable
      When a Caller requests a greeting without supplying a name
      Then the Caller receives a greeting that does not address any particular name
