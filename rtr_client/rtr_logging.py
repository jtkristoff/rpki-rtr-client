""" Logging"""
import logging

from logging.handlers import SysLogHandler

# try:
#	import http.client as http_client
# except ImportError:
#	# Python 2
#	import httplib as http_client

DEBUG = 0
INFO = 1

class rfc8210logger(object):
	""" Logging for Cloudflare API"""

	def __init__(self, debug_level, syslog=False):
		""" Logging for RFC8210 protocol"""
		self.logger_level = self._get_logging_level(debug_level)
		#logging.basicConfig(level=self.logger_level)
		request_logger = logging.getLogger("requests.packages.urllib3")
		request_logger.setLevel(self.logger_level)
		request_logger.propagate = debug_level

		if syslog:
			self.use_syslog = True
		else:
			self.use_syslog = False

	def getLogger(self):
		""" Logging for RFC8210 protocol"""
		# create logger
		logger = logging.getLogger('rpki-rtr-client')
		logger.setLevel(self.logger_level)

		ch = logging.StreamHandler()
		ch.setLevel(self.logger_level)

		# create formatter
		formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')

		# add formatter to ch
		ch.setFormatter(formatter)

		# add ch to logger
		logger.addHandler(ch)

		# http_client.HTTPConnection.debuglevel = 1

		# add syslog handler if requested
		if self.use_syslog:
			syslog = SysLogHandler('/dev/log', facility=SysLogHandler.LOG_LOCAL0)
			syslog.setFormatter(logging.Formatter('rpki-rtr-client: %(message)s'))
			logger.addHandler(syslog)
			logger.setLevel('INFO')

		return logger

	def _get_logging_level(self, debug_level):
		""" Logging for RFC8210 protocol"""
		if debug_level:
			return logging.DEBUG
		else:
			return logging.INFO

