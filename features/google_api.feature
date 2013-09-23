Feature: Google API connect
  Application should connect to stubbed google API

Scenario: Connect user to google Api throught Google API Client
  Given I've got authorization at google
  When I connect to google api
  And I can execute api request
  Then I receive google api response
