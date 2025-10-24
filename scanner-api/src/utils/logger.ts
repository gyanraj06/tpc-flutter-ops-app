/**
 * Simple logger utility for structured logging
 */

export enum LogLevel {
  INFO = 'INFO',
  WARN = 'WARN',
  ERROR = 'ERROR',
  DEBUG = 'DEBUG',
}

interface LogEntry {
  timestamp: string;
  level: LogLevel;
  message: string;
  data?: any;
}

class Logger {
  private formatLog(entry: LogEntry): string {
    const { timestamp, level, message, data } = entry;
    let log = `[${timestamp}] [${level}] ${message}`;

    if (data) {
      log += ` | Data: ${JSON.stringify(data)}`;
    }

    return log;
  }

  private createLogEntry(level: LogLevel, message: string, data?: any): LogEntry {
    return {
      timestamp: new Date().toISOString(),
      level,
      message,
      data,
    };
  }

  info(message: string, data?: any): void {
    const entry = this.createLogEntry(LogLevel.INFO, message, data);
    console.log(this.formatLog(entry));
  }

  warn(message: string, data?: any): void {
    const entry = this.createLogEntry(LogLevel.WARN, message, data);
    console.warn(this.formatLog(entry));
  }

  error(message: string, data?: any): void {
    const entry = this.createLogEntry(LogLevel.ERROR, message, data);
    console.error(this.formatLog(entry));
  }

  debug(message: string, data?: any): void {
    if (process.env.NODE_ENV === 'development') {
      const entry = this.createLogEntry(LogLevel.DEBUG, message, data);
      console.debug(this.formatLog(entry));
    }
  }
}

export const logger = new Logger();
