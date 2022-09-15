
<!-- README.md is generated from README.Rmd. Please edit that file -->

# logdriver

<img src="logo/logdriver_hex.png" width="100px" />

Logdriver is a simple free log-management tool for use in small
projects.

# What’s it for?

When you deploy a data-science application to the cloud, like a Shiny
app, a Plumber API, or anything else, your application’s logs are your
most important way of keeping track of it. Are people using it? What are
they using it for? And–perhaps most importantly–if it’s crashing, what’s
going on?

For a small project, it’s hard to know what to do with these logs.
Writing them to `stdout` and monitoring them through your hosting
provider is the simplest option, but it won’t let you do any analytics.
If you’re generating billions of logs per day, you need (and can likely
afford) a commercial log-management solution. But if you’re generating
thousands, or just dozens, of logs per day, these bigger solutions are
likely overkill, and their freemium tiers often limit you to a few days’
worth of log retention.

Logdriver is designed to meet a small project’s log-management needs
simply and freely.

# How does it work?

# Example
