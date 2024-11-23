# hello_from
An example on how to architect, test and develop with Odin. <br/>

We  want a REST-API method to meet new friends but block annoying people. <br/>

The HTTP method is GET /hello/<name> and it will have three types of responses:
- If the person calls the REST-API method for the first time, then the REST-API will respond "Hello, nice to meet you <name>"
- If the person calls the REST-API method for the second time, but after 60 seconds, then the  method will respond "Hello my friend"
- If the person calls the REST-API method repeatedly without waiting 60 seconds, then the method  will respond with "Get away from me"
## Download libraries
```bash
git clone https://github.com/laytan/odin-http
git clone https://github.com/rm4n0s/trace
```

## Build
```bash
odin build .
```

## Test
```bash
 odin test . $> test.log
```


## Run
```bash
./hello_from
```


## Call endpoint
```bash
$ curl http://localhost:6969/hello/manos
Hello, nice to meet you manos

# after 60 seconds
$ curl http://localhost:6969/hello/manos
Hello my friend

# before 60 seconds
$ curl http://localhost:6969/hello/manos
Get away from me
```